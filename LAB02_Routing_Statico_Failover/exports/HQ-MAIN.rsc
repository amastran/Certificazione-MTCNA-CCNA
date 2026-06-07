# LAB 2 — Export HQ-MAIN
# 2026-06-07 10:10:59 by RouterOS 7.22.1
# system id = hgxdNb1cZpO
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether5 ] disable-running-check=no disabled=yes
set [ find default-name=ether6 ] disable-running-check=no
set [ find default-name=ether7 ] disable-running-check=no
set [ find default-name=ether8 ] disable-running-check=no
/ip address
add address=172.16.0.2/30 interface=ether1 network=172.16.0.0
add address=172.16.0.5/30 interface=ether5 network=172.16.0.4
add address=172.16.1.1/30 interface=ether6 network=172.16.1.0
/ip dhcp-client
add interface=ether1 name=client1
/ip route
add comment="to BRANCH LAN 10.2.1.0/24 via BRANCH" dst-address=10.2.1.0/24 gateway=172.16.0.6
add comment="to DATACENTER LAN 10.3.1.0/24 via DC-CORE" dst-address=10.3.1.0/24 gateway=172.16.1.2
add comment="default route via EDGE-GW" dst-address=0.0.0.0/0 gateway=172.16.0.1
add blackhole comment="blackhole test route" dst-address=192.168.99.0/24
/system identity
set name=HQ-MAIN
