# MTCNA Lab 1 — Basics, DHCP and Bridging (EN)

> **Execution date:** 2026-06-05
> **Environment:** GNS3 on server `192.168.28.90:3080`
> **RouterOS:** HQ-MAIN 7.22.1 · BRANCH-01 7.22.1 · EDGE-GW 7.23

---

## Scenario

You are the network admin of a small company with two offices connected by a point-to-point link.

- HQ: three departments on separate VLANs served by a single router.
- BRANCH: flat LAN with DHCP.
- EDGE: border router providing external access via Cloud NAT.

---

## GNS3 Topology (summary)

- Point-to-point links: HQ ↔ BRANCH (172.16.0.4/30), HQ ↔ EDGE (172.16.0.0/30)
- 3 MikroTik routers (HQ-MAIN, BRANCH-01, EDGE-GW)
- 5 VPCS
- Cloud NAT for WAN access

(See original Italian document for ASCII diagram.)

---

## Devices (summary)

- MikroTik CHR: HQ-MAIN, BRANCH-01, EDGE-GW
- VPCS: PC1–PC5
- Cloud NAT: WAN

---

## Addressing scheme (summary)

- MANAGEMENT: 10.1.1.0/24 VLAN 10 (HQ)
- SALES: 10.1.2.0/24 VLAN 20 (HQ)
- PRODUCTION: 10.1.3.0/24 VLAN 30 (HQ)
- LINK-HQ-EDGE: 172.16.0.0/30
- LINK-HQ-BRANCH: 172.16.0.4/30
- BRANCH-LAN: 10.2.1.0/24

Router addresses (examples):
- HQ-MAIN vlan10-mgmt: 10.1.1.1/24
- HQ-MAIN ether1: 172.16.0.2/30 (to EDGE)
- HQ-MAIN ether5: 172.16.0.5/30 (to BRANCH)
- EDGE-GW ether1: 172.16.0.1/30
- BRANCH-01 ether1: 172.16.0.6/30

Client examples: PC1..PC5 as in original file.

---

## GNS3 management via CLI (quick)

Variables:

```bash
GNS3_URL="http://192.168.28.90:3080"
PROJECT_ID="6c00e09d-f4ee-42f9-bbda-62b735c90c87"
```

Check server:

```bash
curl -s "$GNS3_URL/v2/version" | jq
```

List project nodes (example):

```bash
curl -s "$GNS3_URL/v2/projects/$PROJECT_ID/nodes" | jq -r '.[] | [.name, .node_type, .status, (.console_type // "-"), (.console // "-")] | @tsv'
```

Access console (telnet to GNS3 server ports):

```bash
telnet 192.168.28.90 2007   # HQ-MAIN
telnet 192.168.28.90 2005   # EDGE-GW
telnet 192.168.28.90 2006   # BRANCH-01
```

---

## Part A — RouterOS basics (high-level)

A1 — Identity

Set router identity:

```routeros
/system identity set name=HQ-MAIN
```

A2 — Disable unused services (keep SSH and Winbox):

```routeros
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set www-ssl disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
```

A3 — Admin user creation (example):

```routeros
/user add name=netadmin password="Mtcna2026!" group=full
# then remove admin after switching to netadmin
/user remove admin
```

A4 — Logging to disk or remote syslog (concept):

Use /system logging action add ... and /system logging add topics=... to control what is logged. On low-flash devices prefer remote syslog.

Examples in the original IT doc show disk and remote syslog configs.

A5 — Check installed packages

```routeros
/system package print detail
```

A6 — Export and backup

```routeros
/export file=hq-export
/system backup save name=hq-backup
/file print
```

---

## Part B — DHCP (summary)

General flow: create pools → define DHCP networks (gateway, DNS) → add DHCP servers attached to interfaces.

Example for HQ VLANs (short):

```routeros
/ip pool add name=pool-mgmt ranges=10.1.1.50-10.1.1.200
/ip pool add name=pool-vendite ranges=10.1.2.50-10.1.2.200
/ip pool add name=pool-produzione ranges=10.1.3.50-10.1.3.200

/ip dhcp-server network add address=10.1.1.0/24 gateway=10.1.1.1 dns-server=8.8.8.8,1.1.1.1

/ip dhcp-server add name=dhcp-mgmt interface=vlan10-mgmt address-pool=pool-mgmt disabled=no
```

Static lease example and branch DHCP example are present in the Italian doc and kept as-is in commands.

Notes: use add-arp and arp=reply-only as recommended for tighter ARP/DHCP behavior.

---

## Part C — Bridging and VLAN (summary)

High-level sequence:
1. Create bridge
2. Add physical ports to bridge
3. Set PVID on access ports
4. Define bridge VLANs (tagged/untagged)
5. Create VLAN L3 interfaces on the bridge
6. Assign gateway IPs
7. Enable vlan-filtering only at the end

Key commands (example):

```routeros
/interface bridge add name=bridge-hq protocol-mode=rstp vlan-filtering=no
/interface bridge port add bridge=bridge-hq interface=ether2 pvid=10
/interface bridge vlan add bridge=bridge-hq vlan-ids=10 tagged=bridge-hq untagged=ether2
/interface vlan add name=vlan10-mgmt interface=bridge-hq vlan-id=10
/ip address add address=10.1.1.1/24 interface=vlan10-mgmt
/interface bridge set bridge-hq vlan-filtering=yes
```

---

## Part D — Inter-router links (summary)

Assign IPs on router link interfaces (examples):

```routeros
# HQ
/ip address add address=172.16.0.2/30 interface=ether1
/ip address add address=172.16.0.5/30 interface=ether5

# EDGE
/ip address add address=172.16.0.1/30 interface=ether1

# BRANCH
/ip address add address=172.16.0.6/30 interface=ether1
```

Note: DHCP client must NOT be used on point-to-point links; use static IPs there.

---

## Part E — Final checks (summary)

- DHCP client tests on each VLAN (VPCS ip dhcp + ping gateway)
- Confirm inter-VLAN routing: RouterOS routes connected networks by default unless firewall rules block them
- Example firewall rule to block access from SALES to MGMT is shown in the IT doc.

---

## Quick checklist (commands)

See the Italian doc for the full command list; the same checks apply (system identity, ip address, bridge, dhcp-server, arp, ip route, etc.).

---

## Concept recap

- VLANs alone do not provide L3 isolation; use firewall filter rules to isolate networks.
- Use DHCP client only on WAN interfaces that receive IP from upstream; do not use DHCP on router-to-router links.
- For physical MikroTik devices with limited flash, prefer remote syslog over disk logging.

---

Notes

- This is an automated, brief English translation of the original Italian Lab1_Documentazione.md. It preserves commands and key examples but intentionally summarizes explanatory text. Please review for technical accuracy and language nuances.
