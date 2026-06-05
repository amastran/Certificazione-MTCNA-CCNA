# ============================================================
# HQ-MAIN — Configurazione Lab 1 MTCNA
# RouterOS 7.22.1 | system id = JnLNJ5FX37L
# Data: 2026-06-05
# Correzioni applicate rispetto alla config originale:
#   - rimosso DHCP client su ether1 (era errato)
#   - aggiunto IP statico 172.16.0.2/30 su ether1 (link verso EDGE)
#   - aggiunti /ip service disabilitati (A2)
#   - spostata qui la regola firewall inter-VLAN (era su BRANCH per errore)
# ============================================================

/system identity
set name=HQ-MAIN

# --- Servizi disabilitati (A2) ---
/ip service
set ftp disabled=yes
set telnet disabled=yes
set www disabled=yes
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes

# --- Logging su disco (A4) ---
/system logging action
add disk-file-name=syslog name=syslog target=disk

/system logging
add action=syslog topics=info
add action=syslog topics=warning

# --- Bridge HQ con VLAN filtering ---
/interface bridge
add name=bridge-hq protocol-mode=rstp vlan-filtering=no

/interface bridge port
add bridge=bridge-hq interface=ether2 pvid=10
add bridge=bridge-hq interface=ether3 pvid=20
add bridge=bridge-hq interface=ether4 pvid=30

/interface bridge vlan
add bridge=bridge-hq tagged=bridge-hq untagged=ether2 vlan-ids=10
add bridge=bridge-hq tagged=bridge-hq untagged=ether3 vlan-ids=20
add bridge=bridge-hq tagged=bridge-hq untagged=ether4 vlan-ids=30

# Abilita VLAN filtering solo alla fine
/interface bridge
set bridge-hq vlan-filtering=yes

# --- Interfacce VLAN L3 ---
/interface vlan
add arp=reply-only interface=bridge-hq name=vlan10-mgmt vlan-id=10
add arp=reply-only interface=bridge-hq name=vlan20-vendite vlan-id=20
add arp=reply-only interface=bridge-hq name=vlan30-produzione vlan-id=30

# --- Indirizzi IP ---
/ip address
add address=172.16.0.2/30 interface=ether1 comment="Link HQ-EDGE"
add address=172.16.0.5/30 interface=ether5 comment="Link HQ-BRANCH"
add address=10.1.1.1/24   interface=vlan10-mgmt       comment="GW VLAN10 MANAGEMENT"
add address=10.1.2.1/24   interface=vlan20-vendite     comment="GW VLAN20 VENDITE"
add address=10.1.3.1/24   interface=vlan30-produzione  comment="GW VLAN30 PRODUZIONE"

# --- Pool DHCP ---
/ip pool
add name=pool-mgmt       ranges=10.1.1.50-10.1.1.200
add name=pool-vendite    ranges=10.1.2.50-10.1.2.200
add name=pool-produzione ranges=10.1.3.50-10.1.3.200

# --- DHCP server network ---
/ip dhcp-server network
add address=10.1.1.0/24 gateway=10.1.1.1 dns-server=8.8.8.8,1.1.1.1
add address=10.1.2.0/24 gateway=10.1.2.1 dns-server=8.8.8.8,1.1.1.1
add address=10.1.3.0/24 gateway=10.1.3.1 dns-server=8.8.8.8,1.1.1.1

# --- DHCP server (con add-arp) ---
/ip dhcp-server
add add-arp=yes address-pool=pool-mgmt       interface=vlan10-mgmt       lease-time=8h  name=dhcp-mgmt       disabled=no
add add-arp=yes address-pool=pool-vendite    interface=vlan20-vendite     lease-time=4h  name=dhcp-vendite    disabled=no
add add-arp=yes address-pool=pool-produzione interface=vlan30-produzione  lease-time=12h name=dhcp-produzione disabled=no

# --- Lease statici ---
/ip dhcp-server lease
add address=10.1.1.100 mac-address=00:50:79:66:68:02 client-id=1:0:50:79:66:68:2 server=dhcp-mgmt    comment="PC1 MANAGEMENT statico"
add address=10.1.2.100 mac-address=00:50:79:66:68:01 client-id=1:0:50:79:66:68:1 server=dhcp-vendite comment="PC2 VENDITE statico"
add address=10.1.3.100 mac-address=00:50:79:66:68:00 client-id=1:0:50:79:66:68:0 server=dhcp-produzione comment="PC3 PRODUZIONE statico"

# --- Firewall (E4-bis) ---
/ip firewall filter
add chain=forward src-address=10.1.2.0/24 dst-address=10.1.1.0/24 action=drop comment="Vendite NON accede a Mgmt"
