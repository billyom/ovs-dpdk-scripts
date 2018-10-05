#!/usr/bin/env bash

# This file contains a place to put standard code that is common across several
# test scripts. All the functions should be called std_...

# Globals that various std functions will populate
declare DPDK_IGB_UIO
declare DPDK_BIND_TOOL
declare -A STD_IFACE_TO_PORT # map "iface_name" -> openflow port no

# Some settings that don't change often enough to warrant being in the env file
declare DPDK_SOCKET_MEM="1024,1024"
declare DPDK_LCORE_MASK="0x1"
declare VHU_SOCK_DIR=/tmp

# Load the ovs schema and start ovsdb.
std_start_db() {
    sudo rm /usr/local/etc/openvswitch/conf.db
    sudo $OVS_DIR/ovsdb/ovsdb-tool \
        create /usr/local/etc/openvswitch/conf.db \
        $OVS_DIR/vswitchd/vswitch.ovsschema
    sudo $OVS_DIR/ovsdb/ovsdb-server \
        --remote=punix:/usr/local/var/run/openvswitch/db.sock \
        --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
        --pidfile --detach
}

function std_stop_db() {
    sudo $OVS_DIR/utilities/ovs-appctl --timeout=3 -t ovsdb-server exit
    sleep 1
    sudo pkill -9 ovsdb-server
}

function std_stop_ovs() {
    sudo $OVS_DIR/utilities/ovs-appctl --timeout=3 -t ovs-vswitchd exit
    sleep 1
    sudo rm -rf /usr/local/var/log/openvswitch/*
    sudo rm -rf /usr/local/var/run/openvswitch/*
    sudo rm -rf /usr/local/etc/openvswitch/*
    sudo pkill -9 ovs-vsctl
    sudo pkill -9 pmd*
    sudo pkill -9 ovs-vswitchd
}

function std_umount() {
    sudo umount $HUGE_DIR
}

function std_mount() {
    std_umount
    mkdir -p $HUGE_DIR
    sudo mount -t hugetlbfs nodev $HUGE_DIR
}

function std_bind_kernel() {
    sudo $DPDK_DIR/tools/dpdk-devbind.py --unbind $DPDK_PCI1 $DPDK_PCI2 $DPDK_PCI3 $DPDK_PCI4
    sudo modprobe $KERNEL_NIC_DRV
    sudo $DPDK_BIND_TOOL --bind=$KERNEL_NIC_DRV $DPDK_PCI1 $DPDK_PCI2
}

function std_stop_vms() {
    sudo pkill qemu
}

function std_clean {
    std_stop_vms
    std_stop_ovs
    std_stop_db
    std_umount
}



# creates a dpdk interface for each pci device in STD_NICS array and a number of
# vhuclient ifaces based on $1 arg.
#
# $1 the number of vhostuserclient ifaces to create
#
# OUT creates STD_IFACE_TO_PORT # map "iface_name" -> openflow port no
#     e.g. use ${IFACE_TO_PORT[dpdk_0]} in ofctl cmds as OF port num of
#     first NIC port

function std_create_ifaces() {
    VHOST_IFACE_NAME_BASE=vhu_
    DPDK_IFACE_NAME_BASE=dpdk_
    # Turn comma/space separated string into array
    IFS=', ' read -r -a STD_NICS <<< "$DPDK_NICS"
    NUM_DPDK_IFACES=${#STD_NICS[@]}
    port_no=1
    #declare -A STD_IFACE_TO_PORT # map "iface_name" -> openflow port no

    for idx in $(seq 0 $[$NUM_DPDK_IFACES-1])
    do
        IFACE_NAME="${DPDK_IFACE_NAME_BASE}${idx}"
        sudo $OVS_DIR/utilities/ovs-vsctl --timeout 10  add-port br0 $IFACE_NAME \
		    -- set Interface $IFACE_NAME type=dpdk \
            options:dpdk-devargs=${STD_NICS[$idx]}     \
            options:n_rxq=1                        \
			ofport_request=$port_no
        STD_IFACE_TO_PORT[$IFACE_NAME]=$port_no
        port_no=$[$port_no+1]
    done

    # options:dpdk-lsc-interrupt=true        \

    for idx in $(seq 0 $[$NUM_VHOST_IFACES-1])
    do
        IFACE_NAME="${VHOST_IFACE_NAME_BASE}${idx}"
        sudo $OVS_DIR/utilities/ovs-vsctl --timeout 10 add-port br0 $IFACE_NAME \
          -- set Interface $IFACE_NAME type=dpdkvhostuserclient   \
            options:vhost-server-path="${VHU_SOCK_DIR}/${IFACE_NAME}" \
			ofport_request=$port_no
        STD_IFACE_TO_PORT[$IFACE_NAME]=$port_no
        port_no=$[$port_no+1]
    done
}


function std_start_vm() {
    # $1 the number of the vm to start. This is used as an index to determine
    #     many things about the vm: name, vhu server socket, admin ssh port etc.

    id=$(printf "%d" $1)
    idhex=$(printf "%02X" $1)

    VM_NAME=us-vhost-vm_$id
    VHU_SOCK_NAME=vhu_${id}
    VHOST_MAC=00:00:00:00:01:$idhex
    SSH_PORT=$[2000 + $1]
    NUM_CORES=2
    MEM=2G

    sudo -E taskset -c 3-13 $QEMU_DIR/x86_64-softmmu/qemu-system-x86_64 \
      -name $VM_NAME -cpu host -enable-kvm -m $MEM \
      -object memory-backend-file,id=mem,size=$MEM,mem-path=$HUGE_DIR,share=on \
      -numa node,memdev=mem -mem-prealloc -smp $NUM_CORES \
      -drive file=$VM_IMAGE \
      \
      -chardev socket,id=char0,path=$VHU_SOCK_DIR/$VHU_SOCK_NAME,server \
      -netdev type=vhost-user,id=mynet1,chardev=char0,vhostforce \
      -device virtio-net-pci,mac=${VHOST_MAC},netdev=mynet1,mrg_rxbuf=off \
      \
      -net nic \
      -net user,id=ctlnet,net=20.0.0.0/8,host=20.0.0.1,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22 \
      -vnc :${id},password \
      -snapshot -daemonize

    echo "ssh to VM $1 with 'ssh -p $SSH_PORT <vm-user>@localhost"
}

####################################
#  DPDK specific functions         #
####################################

#Set environment specific for DPDK version
set_dpdk_env() {
    DPDK_IGB_UIO=$(find $DPDK_DIR -name igb_uio.ko | head -1 )
    DPDK_BIND_TOOL=$(find $DPDK_DIR -name dpdk-devbind.py | head -1 )
    if [ -z $DPDK_BIND_TOOL ]; then
        DPDK_BIND_TOOL=$(find $DPDK_DIR -name dpdk_nic_bind.py | head -1 )
    fi

    echo "Found igb_uio: " $DPDK_IGB_UIO
    echo "Found dpdk bind: " $DPDK_BIND_TOOL
    $DPDK_BIND_TOOL --status-dev net
}

