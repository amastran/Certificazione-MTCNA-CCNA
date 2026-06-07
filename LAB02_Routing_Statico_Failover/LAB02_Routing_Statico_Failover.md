# LAB 2 — Routing Statico e Failover

## Obiettivo del laboratorio

Il laboratorio implementa una topologia routed composta da quattro router MikroTik CHR:

- `EDGE-GW`
- `HQ-MAIN`
- `BRANCH`
- `DC-CORE`

L’obiettivo è configurare:

- collegamenti punto-punto `/30`;
- LAN Branch;
- LAN Datacenter;
- routing statico;
- rotte primarie e di backup;
- ECMP da Branch verso Datacenter;
- rotta blackhole su HQ;
- test di failover.

---

## Topologia finale

```text
                [Cloud NAT]
                    |
                  ether2
                [EDGE-GW]
                  ether1
                    |
                  ether1
                [HQ-MAIN]
              ether5   ether6
                /        \
          ether1          ether1
        [BRANCH] ------ [DC-CORE]
          ether4          ether2
            |               |
        bridge-br       bridge-dc
          ether5          ether3
            |               |
       LAN Branch       LAN Datacenter
       10.2.1.0/24     10.3.1.0/24
```

---

## Piano indirizzamento

| Collegamento | Router A | IP A | Router B | IP B | Subnet |
|---|---|---:|---|---:|---|
| EDGE ↔ HQ | `EDGE-GW ether1` | `172.16.0.1/30` | `HQ-MAIN ether1` | `172.16.0.2/30` | `172.16.0.0/30` |
| HQ ↔ BRANCH | `HQ-MAIN ether5` | `172.16.0.5/30` | `BRANCH ether1` | `172.16.0.6/30` | `172.16.0.4/30` |
| HQ ↔ DC | `HQ-MAIN ether6` | `172.16.1.1/30` | `DC-CORE ether1` | `172.16.1.2/30` | `172.16.1.0/30` |
| BRANCH ↔ DC | `BRANCH ether4` | `172.16.1.5/30` | `DC-CORE ether2` | `172.16.1.6/30` | `172.16.1.4/30` |

---

## LAN configurate

| Router | Bridge | Porta LAN | Gateway | Rete |
|---|---|---|---:|---|
| `BRANCH` | `bridge-br` | `ether5` | `10.2.1.1/24` | `10.2.1.0/24` |
| `DC-CORE` | `bridge-dc` | `ether3` | `10.3.1.1/24` | `10.3.1.0/24` |

---

# Configurazione finale per router

---

## EDGE-GW

### Ruolo

`EDGE-GW` rappresenta l’uscita verso Cloud NAT / Internet e inoltra il traffico verso le reti interne passando da `HQ-MAIN`.

### Configurazione rilevante

```routeros
/system identity
set name=EDGE-GW

/ip address
add address=172.16.0.1/30 interface=ether1 network=172.16.0.0

/ip dhcp-client
add interface=ether2 name=client2
```

### Routing previsto

| Destinazione | Gateway | Note |
|---|---|---|
| `10.1.1.0/24` | `172.16.0.2` | HQ LAN via HQ-MAIN |
| `10.1.2.0/24` | `172.16.0.2` | HQ LAN via HQ-MAIN |
| `10.1.3.0/24` | `172.16.0.2` | HQ LAN via HQ-MAIN |
| `10.2.1.0/24` | `172.16.0.2` | Branch LAN via HQ-MAIN |
| `10.3.1.0/24` | `172.16.0.2` | Datacenter LAN via HQ-MAIN |

### Nota di bonifica

Nell’export finale di `EDGE-GW` risultano alcune rotte duplicate verso `10.1.1.0/24`, `10.1.2.0/24` e `10.1.3.0/24`.

Ai fini del laboratorio è sufficiente mantenere una sola rotta per ciascuna destinazione via `172.16.0.2`.

Inoltre nell’export finale di `EDGE-GW` risultano anche:

```routeros
/ip route
add comment="default route via EDGE-GW" dst-address=0.0.0.0/0 gateway=172.16.0.1
add blackhole comment="blackhole test route" dst-address=192.168.99.0/24
```

La rotta blackhole è richiesta dal laboratorio su `HQ-MAIN`, non su `EDGE-GW`.  
La default route verso `172.16.0.1` su EDGE punta al suo stesso IP di transito e non è necessaria.

---

## HQ-MAIN

### Ruolo

`HQ-MAIN` è il router centrale della topologia. Collega:

- `EDGE-GW`;
- `BRANCH`;
- `DC-CORE`.

### Configurazione rilevante

```routeros
/system identity
set name=HQ-MAIN

/ip address
add address=172.16.0.2/30 interface=ether1 network=172.16.0.0
add address=172.16.0.5/30 interface=ether5 network=172.16.0.4
add address=172.16.1.1/30 interface=ether6 network=172.16.1.0
```

### Rotte configurate

```routeros
/ip route
add comment="to BRANCH LAN 10.2.1.0/24 via BRANCH" dst-address=10.2.1.0/24 gateway=172.16.0.6
add comment="to DATACENTER LAN 10.3.1.0/24 via DC-CORE" dst-address=10.3.1.0/24 gateway=172.16.1.2
add comment="default route via EDGE-GW" dst-address=0.0.0.0/0 gateway=172.16.0.1
add blackhole comment="blackhole test route" dst-address=192.168.99.0/24
```

### Stato rotte

| Destinazione | Gateway / Tipo | Stato |
|---|---|---|
| `10.2.1.0/24` | `172.16.0.6` | verso Branch |
| `10.3.1.0/24` | `172.16.1.2` | verso Datacenter |
| `0.0.0.0/0` | `172.16.0.1` | default verso Edge |
| `192.168.99.0/24` | blackhole | rotta blackhole richiesta |

### Nota sul test failover

Nell’export finale `ether5` risulta disabilitata:

```routeros
/interface ethernet
set [ find default-name=ether5 ] disable-running-check=no disabled=yes
```

Questo è coerente con il test di failover eseguito disattivando il link `HQ-MAIN ↔ BRANCH`.

Per riportare il laboratorio in stato nominale, `ether5` va riabilitata.

---

## BRANCH

### Ruolo

`BRANCH` rappresenta la sede remota. Ha:

- un link verso `HQ-MAIN`;
- un link diretto verso `DC-CORE`;
- una LAN locale `10.2.1.0/24`;
- ECMP verso la LAN Datacenter.

### Configurazione rilevante

```routeros
/system identity
set name=BRANCH

/interface bridge
add name=bridge-br

/interface bridge port
add bridge=bridge-br interface=ether5

/ip address
add address=172.16.0.6/30 interface=ether1 network=172.16.0.4
add address=10.2.1.1/24 interface=bridge-br network=10.2.1.0
add address=172.16.1.5/30 interface=ether4 network=172.16.1.4
```

### Rotte verso LAN HQ

`BRANCH` raggiunge le reti HQ `10.1.x.0/24` con percorso primario via `HQ-MAIN` e backup via `DC-CORE`.

| Destinazione | Gateway | Distance | Ruolo |
|---|---|---:|---|
| `10.1.1.0/24` | `172.16.0.5` | `1` | primaria via HQ |
| `10.1.1.0/24` | `172.16.1.6` | `10` | backup via DC |
| `10.1.2.0/24` | `172.16.0.5` | `1` | primaria via HQ |
| `10.1.2.0/24` | `172.16.1.6` | `10` | backup via DC |
| `10.1.3.0/24` | `172.16.0.5` | `1` | primaria via HQ |
| `10.1.3.0/24` | `172.16.1.6` | `10` | backup via DC |

### ECMP verso Datacenter

Il laboratorio richiede ECMP da `BRANCH` verso la LAN Datacenter `10.3.1.0/24`.

Sono state disabilitate le vecchie rotte primaria/backup ed aggiunte due rotte con stessa distance.

```routeros
/ip route
add check-gateway=ping comment="ECMP to DATACENTER LAN via HQ-MAIN" distance=1 dst-address=10.3.1.0/24 gateway=172.16.0.5
add check-gateway=ping comment="ECMP to DATACENTER LAN via direct DC-CORE link" distance=1 dst-address=10.3.1.0/24 gateway=172.16.1.6
```

| Destinazione | Gateway | Distance | Percorso |
|---|---|---:|---|
| `10.3.1.0/24` | `172.16.0.5` | `1` | BRANCH → HQ → DC |
| `10.3.1.0/24` | `172.16.1.6` | `1` | BRANCH → DC diretto |

RouterOS marca queste rotte con flag `+`, quindi vengono trattate come ECMP.

### Rotte di transito

Sono presenti anche rotte verso le subnet di transito:

| Destinazione | Gateway primario | Gateway backup |
|---|---|---|
| `172.16.0.0/30` | `172.16.0.5` | `172.16.1.6` |
| `172.16.1.0/30` | `172.16.0.5` | `172.16.1.6` |

### Test eseguito

Durante il test con `ether5` disabilitata su `HQ-MAIN`, `BRANCH` ha continuato a raggiungere `DC-CORE`:

```routeros
/ping 10.3.1.1
```

Risultato:

```text
sent=6 received=6 packet-loss=0%
min-rtt=808us avg-rtt=966us max-rtt=1ms146us
```

Stato:

```text
Failover BRANCH → DC-CORE: OK
```

---

## DC-CORE

### Ruolo

`DC-CORE` rappresenta il router Datacenter. Ha:

- un link verso `HQ-MAIN`;
- un link diretto verso `BRANCH`;
- una LAN Datacenter `10.3.1.0/24`;
- failover verso le LAN HQ;
- percorso primario diretto verso la LAN Branch.

### Configurazione rilevante

```routeros
/system identity
set name=DC-CORE

/interface bridge
add name=bridge-dc

/interface bridge port
add bridge=bridge-dc interface=ether3

/ip address
add address=172.16.1.2/30 interface=ether1 network=172.16.1.0
add address=10.3.1.1/24 interface=bridge-dc network=10.3.1.0
add address=172.16.1.6/30 interface=ether2 network=172.16.1.4
```

### Rotte verso LAN Branch

`DC-CORE` raggiunge la LAN Branch usando come percorso primario il link diretto verso `BRANCH`.

| Destinazione | Gateway | Distance | Ruolo |
|---|---|---:|---|
| `10.2.1.0/24` | `172.16.1.5` | `1` | primaria diretta |
| `10.2.1.0/24` | `172.16.1.1` | `10` | backup via HQ |

### Rotte verso LAN HQ

`DC-CORE` raggiunge le LAN HQ tramite `HQ-MAIN`, con backup tramite `BRANCH`.

| Destinazione | Gateway | Distance | Check gateway | Ruolo |
|---|---|---:|---|---|
| `10.1.1.0/24` | `172.16.1.1` | `1` | ping | primaria via HQ |
| `10.1.1.0/24` | `172.16.1.5` | `10` | — | backup via Branch |
| `10.1.2.0/24` | `172.16.1.1` | `1` | ping | primaria via HQ |
| `10.1.2.0/24` | `172.16.1.5` | `10` | — | backup via Branch |
| `10.1.3.0/24` | `172.16.1.1` | `1` | ping | primaria via HQ |
| `10.1.3.0/24` | `172.16.1.5` | `10` | — | backup via Branch |

### Rotte verso subnet di transito

| Destinazione | Gateway primario | Gateway backup |
|---|---|---|
| `172.16.0.0/30` | `172.16.1.1` | `172.16.1.5` |
| `172.16.0.4/30` | `172.16.1.1` | `172.16.1.5` |

---

# Verifiche eseguite

## Verifica BRANCH → DC-CORE

Con `ether5` su `HQ-MAIN` disabilitata, `BRANCH` ha raggiunto `10.3.1.1`.

```routeros
/ping 10.3.1.1
```

Risultato:

```text
sent=6 received=6 packet-loss=0%
min-rtt=808us avg-rtt=966us max-rtt=1ms146us
```

Esito:

```text
OK
```

---

# Note finali

## Rotta blackhole

La rotta blackhole richiesta è presente su `HQ-MAIN`:

```routeros
/ip route
add blackhole comment="blackhole test route" dst-address=192.168.99.0/24
```

Una rotta blackhole scarta localmente il traffico destinato alla rete indicata.  
In questo laboratorio serve a dimostrare come RouterOS possa bloccare esplicitamente una destinazione a livello routing.

## ECMP

L’ECMP è stato implementato su `BRANCH` verso `10.3.1.0/24`.

Il concetto è:

```text
stessa destinazione + stessa distance = percorsi equivalenti
```

Nel laboratorio:

```text
BRANCH → HQ-MAIN → DC-CORE
BRANCH → DC-CORE
```

## Failover

Sono state configurate rotte con distance diversa per realizzare il failover:

```text
distance=1  percorso primario
distance=10 percorso backup
```

Esempi:

- `BRANCH → LAN HQ`: primaria via HQ, backup via DC;
- `DC-CORE → LAN HQ`: primaria via HQ, backup via Branch;
- `DC-CORE → LAN Branch`: primaria diretta, backup via HQ.

---

# Stato conclusivo

Il laboratorio può essere considerato chiuso.

## Completato

- Identity router.
- Link IP tra tutti i router.
- LAN Branch.
- LAN Datacenter.
- Bridge Datacenter corretto: `bridge-dc`.
- Routing statico principale.
- Rotte di backup.
- ECMP da Branch verso Datacenter.
- Rotta blackhole su HQ.
- Test di failover Branch verso Datacenter.

## Da ricordare

Prima di riutilizzare la topologia in stato nominale, riabilitare `ether5` su `HQ-MAIN`, disabilitata durante il test di failover.

```routeros
/interface ethernet enable ether5
```
