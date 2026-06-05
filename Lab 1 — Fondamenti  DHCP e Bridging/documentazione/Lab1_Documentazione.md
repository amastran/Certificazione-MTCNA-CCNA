# MTCNA Lab 1 — Fondamenti, DHCP e Bridging

> **Data di esecuzione:** 2026-06-05
> **Ambiente:** GNS3 su server `192.168.28.90:3080`
> **RouterOS:** HQ-MAIN 7.22.1 · BRANCH-01 7.22.1 · EDGE-GW 7.23

---

## Scenario

Sei il network admin di una piccola azienda con due sedi collegate da un link punto-punto.

La sede principale, **HQ**, ha tre reparti su VLAN separate serviti da un unico router.
La sede remota, **BRANCH**, ha una rete flat con DHCP.
Un router di frontiera, **EDGE**, fornisce l'accesso verso l'esterno tramite Cloud NAT.

---

## Topologia GNS3

```text
                                      Link HQ ↔ BRANCH
                                      172.16.0.4/30

 [VPCS-PC1] ---- ether2          ether5 ================= ether1 ---- [BRANCH-01] ---- ether2 ---- [VPCS-PC4]
 [VPCS-PC2] ---- ether3           [HQ]                                     |
 [VPCS-PC3] ---- ether4            |                                       ether3 ---- [VPCS-PC5]
                                  ether1
                                    |
                                    | Link HQ ↔ EDGE
                                    | 172.16.0.0/30
                                    |
                                  ether1
                                 [EDGE-GW]
                                  ether2
                                    |
                               [Cloud NAT]
```

---

## Dispositivi

| Tipo | Quantità | Nome | System ID |
|---|---:|---|---|
| MikroTik CHR | 1 | HQ-MAIN | JnLNJ5FX37L |
| MikroTik CHR | 1 | BRANCH-01 | oROeDe3l+TP |
| MikroTik CHR | 1 | EDGE-GW | MPpF0He1aAC |
| VPCS | 5 | PC1–PC5 | — |
| Cloud NAT | 1 | WAN | — |

---

## Schema di indirizzamento

### Reti

| Rete | Subnet | VLAN | Descrizione |
|---|---|---:|---|
| MANAGEMENT | 10.1.1.0/24 | 10 | HQ — Reparto IT / Management |
| VENDITE | 10.1.2.0/24 | 20 | HQ — Reparto Vendite |
| PRODUZIONE | 10.1.3.0/24 | 30 | HQ — Reparto Produzione |
| LINK-HQ-EDGE | 172.16.0.0/30 | — | Collegamento HQ ↔ EDGE |
| LINK-HQ-BRANCH | 172.16.0.4/30 | — | Collegamento HQ ↔ BRANCH |
| BRANCH-LAN | 10.2.1.0/24 | — | Rete locale sede BRANCH |
| EDGE-WAN | DHCP da Cloud NAT | — | WAN EDGE verso Internet |

### Indirizzi dei router

| Dispositivo | Interfaccia | IP | Note |
|---|---|---|---|
| HQ-MAIN | vlan10-mgmt | 10.1.1.1/24 | Gateway VLAN 10 |
| HQ-MAIN | vlan20-vendite | 10.1.2.1/24 | Gateway VLAN 20 |
| HQ-MAIN | vlan30-produzione | 10.1.3.1/24 | Gateway VLAN 30 |
| HQ-MAIN | ether1 | 172.16.0.2/30 | Verso EDGE |
| HQ-MAIN | ether5 | 172.16.0.5/30 | Verso BRANCH |
| EDGE-GW | ether1 | 172.16.0.1/30 | Verso HQ |
| EDGE-GW | ether2 | DHCP client | WAN |
| BRANCH-01 | ether1 | 172.16.0.6/30 | Verso HQ |
| BRANCH-01 | bridge-branch | 10.2.1.1/24 | Gateway LAN |

### Indirizzi dei PC

| PC | Rete | IP | Assegnazione |
|---|---|---|---|
| PC1 | MANAGEMENT | 10.1.1.100/24 | Lease statico (MAC 00:50:79:66:68:02) |
| PC2 | VENDITE | 10.1.2.100/24 | Lease statico (MAC 00:50:79:66:68:01) |
| PC3 | PRODUZIONE | 10.1.3.100/24 | Lease statico (MAC 00:50:79:66:68:00) |
| PC4 | BRANCH-LAN | 10.2.1.x/24 | DHCP dinamico, pool .10–.100 |
| PC5 | BRANCH-LAN | 10.2.1.200/24 | Lease statico (MAC 00:50:79:66:68:04) |

---

## Gestione GNS3 da CLI

### Setup variabili

```bash
GNS3_URL="http://192.168.28.90:3080"
PROJECT_ID="6c00e09d-f4ee-42f9-bbda-62b735c90c87"
```

Verifica server:

```bash
curl -s "$GNS3_URL/v2/version" | jq
```

### Lista nodi del progetto

```bash
printf "%-22s %-18s %-10s %-12s %s\n" "NAME" "TYPE" "STATUS" "CONSOLE" "PORT"

curl -s "$GNS3_URL/v2/projects/$PROJECT_ID/nodes" |
jq -r '
.[] |
[.name, .node_type, .status, (.console_type // "-"), (.console // "-")] | @tsv
' | while IFS=$'\t' read -r name type status console port; do
    printf "%-22s %-18s %-10s %-12s %s\n" "$name" "$type" "$status" "$console" "$port"
done
```

Output di riferimento:

```text
NAME                   TYPE               STATUS     CONSOLE      PORT
WAN                    nat                started    none         -
EDGE-GW                qemu               started    telnet       2005
HQ-MAIN                qemu               started    telnet       2007
BRANCH-01              qemu               started    telnet       2006
```

### Accesso console router

```bash
telnet 192.168.28.90 2007   # HQ-MAIN
telnet 192.168.28.90 2005   # EDGE-GW
telnet 192.168.28.90 2006   # BRANCH-01
```

### Flusso mentale GNS3 CLI

```text
/v2/projects  →  PROJECT_ID  →  /v2/projects/<ID>/nodes  →  console_type + porta  →  telnet
```

---

## Parte A — Fondamenti RouterOS

### A1 — Identity

```routeros
/system identity set name=HQ-MAIN     # su HQ
/system identity set name=EDGE-GW     # su EDGE
/system identity set name=BRANCH-01   # su BRANCH
```

### A2 — Servizi disabilitati

Su tutti i router, tenere attivi solo SSH (22) e Winbox (8291):

```routeros
/ip service set ftp      disabled=yes
/ip service set telnet   disabled=yes
/ip service set www      disabled=yes
/ip service set www-ssl  disabled=yes
/ip service set api      disabled=yes
/ip service set api-ssl  disabled=yes
```

### A3 — Utente amministrativo su HQ

```routeros
/user add name=netadmin password="Mtcna2026!" group=full
# Dopo aver effettuato l'accesso come netadmin:
/user remove admin
```

> Non rimuovere `admin` mentre si è ancora collegati come `admin`.

### A4 — Logging su disco

Flusso mentale:

```text
ACTION  =  dove scrivo i log
TOPIC   =  quali log voglio
RULE    =  topic → action
```

```routeros
/system logging action add name=syslog target=disk disk-file-name=syslog
/system logging add topics=info    action=syslog
/system logging add topics=warning action=syslog
```

**Nota — CHR vs MikroTik fisico:**

Su CHR e in laboratorio `target=disk` è accettabile per imparare.
Su hardware fisico con poca flash, meglio usare un syslog server remoto.

Esempio con syslog server su `192.168.28.31` (Zimaboard):

```routeros
/system logging action add name=remotesyslog target=remote \
  remote=192.168.28.31 remote-port=514 src-address=192.168.28.1

/system logging add topics=warning  action=remotesyslog
/system logging add topics=error    action=remotesyslog
/system logging add topics=critical action=remotesyslog
```

Il topic `info` è molto rumoroso: abilitarlo solo durante troubleshooting mirato.

Test manuale:

```routeros
/log warning "TEST SYSLOG REMOTO"
```

Verifica sul server:

```bash
sudo grep -i "TEST SYSLOG" /var/log/mikrotik/192.168.28.1.log
```

### A5 — Pacchetti su EDGE

```routeros
/system package print detail
```

### A6 — Export e backup

```routeros
/export file=hq-export       # testo leggibile, per studio e documentazione
/system backup save name=hq-backup  # binario, per ripristino completo
/file print
```

| Tipo | Formato | Uso |
|---|---|---|
| `/export` | Testo leggibile `.rsc` | Studio, confronto, migrazione |
| `/system backup save` | Binario `.backup` | Ripristino completo sullo stesso router |

---

## Parte B — DHCP

> Su HQ, i DHCP server delle VLAN richiedono che esistano già le interfacce VLAN (Parte C, passi C1–C5). Eseguire prima C1–C5, poi tornare qui.

### Flusso mentale DHCP

```text
POOL     =  quali indirizzi posso assegnare
NETWORK  =  gateway, DNS, subnet da dare ai client
SERVER   =  su quale interfaccia ascolto e quale pool uso
LEASE    =  chi ha ricevuto un IP
```

Formula:

```text
Prima preparo gli indirizzi.
Poi preparo le informazioni da dare ai client.
Poi accendo il DHCP server sull'interfaccia corretta.
```

### B1 — DHCP server su HQ (3 VLAN)

```routeros
/ip pool add name=pool-mgmt       ranges=10.1.1.50-10.1.1.200
/ip pool add name=pool-vendite    ranges=10.1.2.50-10.1.2.200
/ip pool add name=pool-produzione ranges=10.1.3.50-10.1.3.200

/ip dhcp-server network add address=10.1.1.0/24 gateway=10.1.1.1 dns-server=8.8.8.8,1.1.1.1
/ip dhcp-server network add address=10.1.2.0/24 gateway=10.1.2.1 dns-server=8.8.8.8,1.1.1.1
/ip dhcp-server network add address=10.1.3.0/24 gateway=10.1.3.1 dns-server=8.8.8.8,1.1.1.1

/ip dhcp-server add name=dhcp-mgmt       interface=vlan10-mgmt       address-pool=pool-mgmt       add-arp=yes lease-time=8h  disabled=no
/ip dhcp-server add name=dhcp-vendite    interface=vlan20-vendite     address-pool=pool-vendite    add-arp=yes lease-time=4h  disabled=no
/ip dhcp-server add name=dhcp-produzione interface=vlan30-produzione  address-pool=pool-produzione add-arp=yes lease-time=12h disabled=no
```

### B2 — Lease statico PC1

```routeros
/ip dhcp-server lease print
/ip dhcp-server lease make-static [find where active-mac-address="00:50:79:66:68:02"]
/ip dhcp-server lease set [find where mac-address="00:50:79:66:68:02"] address=10.1.1.100 comment="PC1 MANAGEMENT statico"
```

### B3 — DHCP server su BRANCH

```routeros
/ip pool add name=pool-branch ranges=10.2.1.10-10.2.1.100

/ip dhcp-server network add address=10.2.1.0/24 gateway=10.2.1.1 dns-server=8.8.8.8

/ip dhcp-server add name=dhcp-branch interface=bridge-branch address-pool=pool-branch add-arp=yes lease-time=6h disabled=no
```

### B4 — Lease statico PC5

```routeros
/ip dhcp-server lease make-static [find where active-mac-address="00:50:79:66:68:04"]
/ip dhcp-server lease set [find where mac-address="00:50:79:66:68:04"] address=10.2.1.200 comment="PC5 BRANCH statico"
```

### B5 — DHCP client su EDGE (WAN)

```routeros
/ip dhcp-client add interface=ether2 disabled=no comment="DHCP VERSO WAN"
```

> Il DHCP client va usato **solo** su interfacce WAN che ricevono IP da un provider.
> I link punto-punto tra router (es. HQ ether1 ↔ EDGE ether1) devono avere IP statici.

### B6 — add-arp e reply-only

```routeros
# Su HQ
/ip dhcp-server set dhcp-mgmt       add-arp=yes
/ip dhcp-server set dhcp-vendite    add-arp=yes
/ip dhcp-server set dhcp-produzione add-arp=yes
/interface vlan set vlan10-mgmt       arp=reply-only
/interface vlan set vlan20-vendite    arp=reply-only
/interface vlan set vlan30-produzione arp=reply-only

# Su BRANCH
/ip dhcp-server set dhcp-branch add-arp=yes
/interface bridge set bridge-branch arp=reply-only
```

**Test pratico:**

```text
VPCS> ip 10.1.2.240/24 10.1.2.1    # IP statico fuori pool su PC2
VPCS> ping 10.1.2.1                 # DEVE FALLIRE
```

```routeros
/ip arp print                        # 10.1.2.240 non deve comparire
```

```text
VPCS> ip dhcp                        # ripristino
```

---

## Parte C — Bridging e VLAN

### Flusso mentale bridge VLAN

```text
1. Creo il bridge
2. Aggiungo le porte fisiche al bridge
3. Imposto il PVID sulle porte access
4. Dichiaro le VLAN sul bridge (tagged / untagged)
5. Creo le interfacce VLAN L3 sul bridge
6. Assegno gli IP gateway alle VLAN
7. Abilito vlan-filtering=yes solo alla fine
```

Schema mentale:

```text
BRIDGE PORT    =  porta fisica dentro il bridge
PVID           =  VLAN access della porta
BRIDGE VLAN    =  tabella VLAN: chi è tagged, chi è untagged
INTERFACE VLAN =  interfaccia L3 del router dentro quella VLAN
IP ADDRESS     =  gateway della subnet
```

Regola add vs set:

```text
add   →  creo una nuova riga
set   →  modifico una riga esistente
print →  vedo le righe
find  →  cerco la riga automaticamente
```

Se la porta è già nel bridge e riprovo con `add`:

```text
failure: device already added as bridge port
→ usare set, non add
```

### C1-C5 — Bridge HQ con VLAN filtering (sequenza completa)

```routeros
/interface bridge add name=bridge-hq protocol-mode=rstp vlan-filtering=no

/interface bridge port add bridge=bridge-hq interface=ether2 pvid=10
/interface bridge port add bridge=bridge-hq interface=ether3 pvid=20
/interface bridge port add bridge=bridge-hq interface=ether4 pvid=30

/interface bridge vlan add bridge=bridge-hq vlan-ids=10 tagged=bridge-hq untagged=ether2
/interface bridge vlan add bridge=bridge-hq vlan-ids=20 tagged=bridge-hq untagged=ether3
/interface bridge vlan add bridge=bridge-hq vlan-ids=30 tagged=bridge-hq untagged=ether4

/interface vlan add name=vlan10-mgmt       interface=bridge-hq vlan-id=10
/interface vlan add name=vlan20-vendite    interface=bridge-hq vlan-id=20
/interface vlan add name=vlan30-produzione interface=bridge-hq vlan-id=30

/ip address add address=10.1.1.1/24 interface=vlan10-mgmt
/ip address add address=10.1.2.1/24 interface=vlan20-vendite
/ip address add address=10.1.3.1/24 interface=vlan30-produzione

# Solo alla fine:
/interface bridge set bridge-hq vlan-filtering=yes
```

Verifica:

```routeros
/interface bridge print
/interface bridge port print detail
/interface bridge vlan print
/interface vlan print
/ip address print
```

### C6 — Bridge BRANCH (flat, senza VLAN)

```routeros
/interface bridge add name=bridge-branch protocol-mode=rstp
/interface bridge port add bridge=bridge-branch interface=ether2
/interface bridge port add bridge=bridge-branch interface=ether3
/ip address add address=10.2.1.1/24 interface=bridge-branch comment="GW BRANCH LAN"
```

### C7 — Verifica STP/RSTP

```routeros
/interface bridge print
/interface bridge port print detail
```

> Con la topologia di questo lab, ogni bridge è root di sé stesso e tutte le porte
> risultano edge/designated: non esistono percorsi L2 ridondanti (i link interrouter
> sono routed a L3). STP sarà rilevante nei lab con switch Cisco.

---

## Parte D — IP link interrouter

```routeros
# Su HQ
/ip address add address=172.16.0.2/30 interface=ether1 comment="Link HQ-EDGE"
/ip address add address=172.16.0.5/30 interface=ether5 comment="Link HQ-BRANCH"

# Su EDGE
/ip address add address=172.16.0.1/30 interface=ether1 comment="Link EDGE-HQ"

# Su BRANCH
/ip address add address=172.16.0.6/30 interface=ether1 comment="Link BRANCH-HQ"
```

> Il DHCP client va su interfacce WAN, MAI sui link punto-punto tra router.

---

## Parte E — Verifiche finali

### E1-E3 — DHCP e ping gateway VLAN

```text
VPCS> ip dhcp && show && ping 10.1.1.1   # PC1 → deve ottenere 10.1.1.100
VPCS> ip dhcp && show && ping 10.1.2.1   # PC2 → range .50-.200
VPCS> ip dhcp && show && ping 10.1.3.1   # PC3 → range .50-.200
```

### E4 — Inter-VLAN routing: comportamento di default

- [x] PC1 pinga PC2
- [x] PC1 pinga PC3

**Lezione MTCNA:** assegnare un IP a un'interfaccia VLAN crea automaticamente una rotta connected. RouterOS instrada tra tutte le reti connected. Senza firewall, le VLAN **non sono isolate a L3**.

```routeros
/ip route print   # le VLAN compaiono come DAC (directly connected)
```

### E4-bis — Isolamento esplicito

```routeros
/ip firewall filter add chain=forward \
  src-address=10.1.2.0/24 dst-address=10.1.1.0/24 \
  action=drop comment="Vendite NON accede a Mgmt"
```

- [x] PC2 non pinga PC1
- [x] PC1 pinga ancora PC2 (regola unidirezionale)

### E5 — BRANCH

```text
VPCS> ip dhcp && show && ping 10.2.1.1   # PC4 → range .10-.100
VPCS> ip dhcp && show && ping 10.2.1.1   # PC5 → deve ottenere 10.2.1.200
```

### E6 — Link interrouter

```routeros
/ping 172.16.0.1   # HQ → EDGE
/ping 172.16.0.6   # HQ → BRANCH
```

---

## Checklist rapida

### HQ-MAIN

```routeros
/system identity print
/ip address print
/interface bridge print
/interface bridge port print detail
/interface bridge vlan print
/interface vlan print
/ip dhcp-server print
/ip dhcp-server lease print
/ip arp print
/ip route print
```

### BRANCH-01

```routeros
/system identity print
/ip address print
/interface bridge print
/ip dhcp-server print
/ip dhcp-server lease print
/ip arp print
```

### EDGE-GW

```routeros
/system identity print
/ip address print
/ip dhcp-client print detail
/ip route print
/ip service print
/system package print
```

---

## Riepilogo concettuale

**VLAN e routing**

```text
VLAN diverse  ≠  isolamento automatico a L3
Per isolare:  →  /ip firewall filter chain=forward
```

**DHCP client**

```text
Usare SOLO su interfacce WAN (che ricevono IP da upstream).
MAI su link punto-punto tra router (usare IP statici).
```

**Logging**

```text
ACTION  →  target (disk / remote / memory)
TOPIC   →  tipo evento (info / warning / error)
RULE    →  collega topic a action
```

**MikroTik fisico con poca flash:** usare `target=remote` verso syslog server. Evitare `target=disk` per topic rumorosi come `info`.
