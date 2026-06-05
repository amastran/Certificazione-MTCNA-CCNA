# ============================================================
# BRANCH-01 — Configurazione Lab 1 MTCNA
# RouterOS 7.22.1 | system id = oROeDe3l+TP
# Data: 2026-06-05
# Correzioni applicate rispetto alla config originale:
#   - rimosso DHCP client su ether1 (era errato, ether1 ha IP statico)
#   - aggiunto gateway=10.2.1.1 nella dhcp-server network (mancava)
#   - rimosse regole firewall per VLAN HQ (erano sul device sbagliato)
#   - rinominato bridge da branch-01 a bridge-branch (coerenza lab)
# ============================================================

/system identity
set name=BRANCH-01

# --- Servizi disabilitati (A2) ---
/ip service
set ftp      disabled=yes
set telnet   disabled=yes
set www      disabled=yes
set www-ssl  disabled=yes
set api      disabled=yes
set api-ssl  disabled=yes

# --- Logging su disco (A4) ---
/system logging action
add disk-file-name=syslog name=syslog target=disk

/system logging
add action=syslog topics=info
add action=syslog topics=warning

# --- Bridge LAN flat (senza VLAN) ---
/interface bridge
add name=bridge-branch protocol-mode=rstp arp=reply-only

/interface bridge port
add bridge=bridge-branch interface=ether2
add bridge=bridge-branch interface=ether3

# --- Indirizzi IP ---
/ip address
add address=172.16.0.6/30 interface=ether1 comment="Link BRANCH-HQ"
add address=10.2.1.1/24   interface=bridge-branch comment="GW BRANCH LAN"

# --- Pool DHCP ---
/ip pool
add name=pool-branch ranges=10.2.1.10-10.2.1.100

# --- DHCP server network (con gateway) ---
/ip dhcp-server network
add address=10.2.1.0/24 gateway=10.2.1.1 dns-server=8.8.8.8

# --- DHCP server (con add-arp) ---
/ip dhcp-server
add add-arp=yes address-pool=pool-branch interface=bridge-branch lease-time=6h name=dhcp-branch disabled=no

# --- Lease statico PC5 ---
/ip dhcp-server lease
add address=10.2.1.200 mac-address=00:50:79:66:68:04 client-id=1:0:50:79:66:68:4 server=dhcp-branch comment="PC5 BRANCH statico"
