#!/bin/bash

print_phy2phy_banner() {
cat <<"EOT"

                                                               
                                                               
                                                               
               \      _ \ / __     /                           
   ------------ >    / \ V (_     < ------------------------   
               /     \_/   __)     \                           
 |                                                           | 
 |                                                           | 
 |                                                           | 
 |                                                           | 
 |                                                           | 
 |                                                           | 
         \     ___        _  _          __           /         
   ------ >     |  __ _ _|__|_ o  _    /__ _ __     < ------   
         /      |  | (_| |  |  | (_    \_|(/_| |     \         

EOT
sleep 3
}

print_PVP_banner() {

# ---->  VM <-------- 
#|                   |
#|                   |
# ---->     <-------- 
#       OVS           
# ---->     <-------- 
#|                   |
#|                   |
# --> Traffic Gen <-- 
cat <<"EOT" 

               \        \ /        /                                 
   ------------ >        V |V|    < ------------------------         
               /           | |     \                                 
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
               \                   /                                 
   ------------ >                 < ------------------------         
               /                   \                                 
                      _ \ / __                                       
                     / \ V (_                                        
                     \_/   __)                                       
               \                   /                                 
   ------------ >                 < ------------------------         
               /                   \                                 
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
 |                                                           |       
         \     ___        _  _          __           /               
   ------ >     |  __ _ _|__|_ o  _    /__ _ __     < ------         
         /      |  | (_| |  |  | (_    \_|(/_| |     \               
EOT
}

print_phy_2vxlan_phy_banner() {
cat <<"EOT"

                   ------                                                                ------
dl_src=00:00:64:00:00:01 |                                                              | dl_src=00:00:64:00:00:01
                         |                                                              |
dl_dst=?                 |                                                              | dl_dst=00:00:64:00:00:02
                         |       \    /    _ \ / __    __          _    \           \   |
nw_src=?                 | ------ > -(    / \ V (_ ---|_ __  _  _ |_)    )-   ------ >  | nw_src=10.0.0.1
                         |       /    \   \_/   __)   |__| |(_ (_||     /           /   |
nw_dst=?                 |                                                              | nw_dst=10.0.0.2
                         |                                                              |
                         |                                                              | vni=1000
                   ------                                                                ------


                   ------                                                                ------
dl_src=00:00:C8:00:00:01 |                                                              | dl_src=00:00:C8:00:00:01
                         |                                                              |
dl_dst=?                 |                                                              | dl_dst=00:00:C8:00:00:02
                         |       \    /    _ \ / __    __          _    \           \   |
nw_src=?                 | ------ > -(    / \ V (_ ---|_ __  _  _ |_)    )-   ------ >  | nw_src=20.0.0.1
                         |       /    \   \_/   __)   |__| |(_ (_||     /           /   |
nw_dst=?                 |                                                              | nw_dst=20.0.0.2
                         |                                                              |
                         |                                                              | vni=2000
                   ------                                                                ------



                   ------                                                                ------
dl_src=00:00:C8:00:00:02 |                                                              | dl_src=?
                         |                                                              |
dl_dst=00:00:C8:00:00:01 |                                                              | dl_dst=?
                         |       \    /    _ \ / __    _           _    \           \   |
nw_src=20.0.0.2          | ------ > -(    / \ V (_ ---| \ _  _  _ |_)    )-   ------ >  | nw_src=?
                         |       /    \   \_/   __)   |_/(/_(_ (_||     /           /   |
nw_dst=20.0.0.1          |                                                              | nw_dst=?
                         |                                                              |
vni=2000                 |                                                              |
                   ------                                                                ------


                   ------                                                                ------
dl_src=00:00:64:00:00:02 |                                                              | dl_src=?
                         |                                                              |
dl_dst=00:00:64:00:00:01 |                                                              | dl_dst=?
                         |       \    /    _ \ / __    _           _    \           \   |
nw_src=10.0.0.2          | ------ > -(    / \ V (_ ---| \ _  _  _ |_)    )-   ------ >  | nw_src=?
                         |       /    \   \_/   __)   |_/(/_(_ (_||     /           /   |
nw_dst=10.0.0.1          |                                                              | nw_dst=?
                         |                                                              |
vni=1000                 |                                                              |
                   ------                                                                ------
EOT
}

print_phy_vxlan_phy_banner() {
cat <<"EOT"

                   ------                                                                ------
dl_src=00:00:64:00:00:01 |                                                              | dl_src=00:00:64:00:00:01
                         |                                                              |
dl_dst=?                 |                                                              | dl_dst=00:00:64:00:00:02
                         |       \    /    _ \ / __    __          _    \           \   |
nw_src=?                 | ------ > -(    / \ V (_ ---|_ __  _  _ |_)    )-   ------ >  | nw_src=10.0.0.1
                         |       /    \   \_/   __)   |__| |(_ (_||     /           /   |
nw_dst=?                 |                                                              | nw_dst=10.0.0.2
                         |                                                              |
                         |                                                              | vni=1000
                   ------                                                                ------


                   ------                                                                ------
dl_src=00:00:64:00:00:02 |                                                              | dl_src=?
                         |                                                              |
dl_dst=00:00:64:00:00:01 |                                                              | dl_dst=?
                         |       \    /    _ \ / __    _           _    \           \   |
nw_src=10.0.0.2          | ------ > -(    / \ V (_ ---| \ _  _  _ |_)    )-   ------ >  | nw_src=?
                         |       /    \   \_/   __)   |_/(/_(_ (_||     /           /   |
nw_dst=10.0.0.1          |                                                              | nw_dst=?
                         |                                                              |
vni=1000                 |                                                              |
                   ------                                                                ------

EOT
sleep 3
}
