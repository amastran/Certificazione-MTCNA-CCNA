# LAB 2 — Export EDGE-GW clean
# versione ripulita: una rotta per destinazione, senza blackhole/default non necessarie su EDGE
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether5 ] disable-running-check=no
set [ find default-name=ether6 ] disable-running-check=no
set [ find default-name=ether7 ] disable-running-check=no
set [ find default-name=ether8 ] disable-running-check=no
/ip address
add address=172.16.0.1/30 interface=ether1 network=172.16.0.0
/ip dhcp-client
add interface=ether2 name=client2
/ip route
add comment="to HQ LAN 10.1.1.0/24 via HQ-MAIN" dst-address=10.1.1.0/24 gateway=172.16.0.2
add comment="to HQ LAN 10.1.2.0/24 via HQ-MAIN" dst-address=10.1.2.0/24 gateway=172.16.0.2
add comment="to HQ LAN 10.1.3.0/24 via HQ-MAIN" dst-address=10.1.3.0/24 gateway=172.16.0.2
add comment="to BRANCH LAN 10.2.1.0/24 via HQ-MAIN" dst-address=10.2.1.0/24 gateway=172.16.0.2
add comment="to DATACENTER LAN 10.3.1.0/24 via HQ-MAIN" dst-address=10.3.1.0/24 gateway=172.16.0.2
/system identity
set name=EDGE-GW
