# ============================================================
# EDGE-GW — Configurazione Lab 1 MTCNA
# RouterOS 7.23 | system id = MPpF0He1aAC
# Data: 2026-06-05
# Correzioni applicate rispetto alla config originale:
#   - identity corretta da "EDGE" a "EDGE-GW" (spec del lab)
#   - rimossi i duplicati logging topics=info e topics=warning
#   - aggiunto www-ssl disabled
# ============================================================

/system identity
set name=EDGE-GW

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

# --- Indirizzi IP ---
/ip address
add address=172.16.0.1/30 interface=ether1 comment="Link EDGE-HQ"

# --- DHCP client WAN ---
/ip dhcp-client
add interface=ether2 default-route-tables=main comment="DHCP VERSO WAN" name=client1 disabled=no
