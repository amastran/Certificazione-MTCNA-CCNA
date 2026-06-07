# LAB 2 — Export DC-CORE
# 2026-06-07 10:11:38 by RouterOS 7.22.1
# system id = 6lyowaD4ryF
#
/interface bridge
add name=bridge-dc
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
add bridge=bridge-dc interface=ether3
/ip address
add address=172.16.1.2/30 interface=ether1 network=172.16.1.0
add address=10.3.1.1/24 interface=bridge-dc network=10.3.1.0
add address=172.16.1.6/30 interface=ether2 network=172.16.1.4
/ip dhcp-client
add interface=ether1 name=client1
/ip route
add check-gateway=ping comment="primary to BRANCH LAN via direct BRANCH link" distance=1 dst-address=10.2.1.0/24 gateway=172.16.1.5
add check-gateway=none comment="backup to BRANCH LAN via HQ-MAIN" distance=10 dst-address=10.2.1.0/24 gateway=172.16.1.1
add check-gateway=ping comment="to EDGE-HQ transit network via HQ-MAIN" dst-address=172.16.0.0/30 gateway=172.16.1.1
add check-gateway=none comment="to EDGE-HQ transit network via BRANCH" distance=10 dst-address=172.16.0.0/30 gateway=172.16.1.5
add check-gateway=ping comment="to HQ-BRANCH transit network via HQ-MAIN" dst-address=172.16.0.4/30 gateway=172.16.1.1
add check-gateway=none comment="to HQ-BRANCH transit network via BRANCH" distance=10 dst-address=172.16.0.4/30 gateway=172.16.1.5
add check-gateway=ping comment="primary to HQ LAN 10.1.1.0/24 via HQ-MAIN" distance=1 dst-address=10.1.1.0/24 gateway=172.16.1.1
add comment="backup to HQ LAN 10.1.1.0/24 via BRANCH" distance=10 dst-address=10.1.1.0/24 gateway=172.16.1.5
add check-gateway=ping comment="primary to HQ LAN 10.1.2.0/24 via HQ-MAIN" distance=1 dst-address=10.1.2.0/24 gateway=172.16.1.1
add comment="backup to HQ LAN 10.1.2.0/24 via BRANCH" distance=10 dst-address=10.1.2.0/24 gateway=172.16.1.5
add check-gateway=ping comment="primary to HQ LAN 10.1.3.0/24 via HQ-MAIN" distance=1 dst-address=10.1.3.0/24 gateway=172.16.1.1
add comment="backup to HQ LAN 10.1.3.0/24 via BRANCH" distance=10 dst-address=10.1.3.0/24 gateway=172.16.1.5
/system identity
set name=DC-CORE
