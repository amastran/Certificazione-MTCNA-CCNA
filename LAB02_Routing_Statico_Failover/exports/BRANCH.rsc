# LAB 2 — Export BRANCH
# 2026-06-07 10:08:15 by RouterOS 7.22.1
# system id = g1QrIDqwJIE
#
/interface bridge
add name=bridge-br
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
set [ find default-name=ether5 ] disable-running-check=no
set [ find default-name=ether6 ] disable-running-check=no
set [ find default-name=ether7 ] disable-running-check=no
set [ find default-name=ether8 ] disable-running-check=no
/interface bridge port
add bridge=bridge-br interface=ether5
/ip address
add address=172.16.0.6/30 interface=ether1 network=172.16.0.4
add address=10.2.1.1/24 interface=bridge-br network=10.2.1.0
add address=172.16.1.5/30 interface=ether4 network=172.16.1.4
/ip dhcp-client
add interface=ether1 name=client1
/ip route
add comment="default route via HQ-MAIN - currently disabled" disabled=yes dst-address=0.0.0.0/0 gateway=172.16.0.5
add check-gateway=ping comment="to DATACENTER LAN via HQ-MAIN" disabled=yes dst-address=10.3.1.0/24 gateway=172.16.0.5
add check-gateway=none comment="to DATACENTER LAN via direct DC link" disabled=yes distance=10 dst-address=10.3.1.0/24 gateway=172.16.1.6
add check-gateway=ping comment="to HQ-DC transit network via HQ-MAIN" dst-address=172.16.1.0/30 gateway=172.16.0.5
add check-gateway=none comment="to HQ-DC transit network via DC-CORE" distance=10 dst-address=172.16.1.0/30 gateway=172.16.1.6
add check-gateway=none comment="to EDGE-HQ transit network via DC-CORE" distance=10 dst-address=172.16.0.0/30 gateway=172.16.1.6
add check-gateway=ping comment="to EDGE-HQ transit network via HQ-MAIN" distance=1 dst-address=172.16.0.0/30 gateway=172.16.0.5
add comment="to HQ LAN 10.1.1.0/24 via HQ-MAIN" dst-address=10.1.1.0/24 gateway=172.16.0.5
add comment="to HQ LAN 10.1.2.0/24 via HQ-MAIN" dst-address=10.1.2.0/24 gateway=172.16.0.5
add comment="to HQ LAN 10.1.3.0/24 via HQ-MAIN" dst-address=10.1.3.0/24 gateway=172.16.0.5
add comment="backup to HQ LAN 10.1.1.0/24 via DC-CORE" distance=10 dst-address=10.1.1.0/24 gateway=172.16.1.6
add comment="backup to HQ LAN 10.1.2.0/24 via DC-CORE" distance=10 dst-address=10.1.2.0/24 gateway=172.16.1.6
add comment="backup to HQ LAN 10.1.3.0/24 via DC-CORE" distance=10 dst-address=10.1.3.0/24 gateway=172.16.1.6
add check-gateway=ping comment="ECMP to DATACENTER LAN via HQ-MAIN" distance=1 dst-address=10.3.1.0/24 gateway=172.16.0.5
add check-gateway=ping comment="ECMP to DATACENTER LAN via direct DC-CORE link" distance=1 dst-address=10.3.1.0/24 gateway=172.16.1.6
/system identity
set name=BRANCH
