# Optimized Defense-in-Depth for IoT

A resource-efficient, multi-layered defense architecture for constrained IoT gateways, implemented as a reproducible Docker-based testbed.

Each layer is mapped to specific design principles defined in [NIST SP 800-160 v1r1](https://doi.org/10.6028/NIST.SP.800-160v1r1) (*Engineering Trustworthy Secure Systems*).

This repository accompanies coursework for the **Security and Continuity of Computer Systems** module at Akademia WSB, Katowice.

---

## Overview

A compact four-layer security architecture for MQTT-based IoT deployments, designed to operate within the resource constraints of an edge gateway such as a Raspberry Pi 4.

| Layer | Component | NIST 800-160 v1r1 principles |
|---|---|---|
| L1 | Mosquitto broker with password file and ACL | E.16 Least Privilege, E.19 Mediated Access |
| L2 | iptables firewall with socat proxy and network segmentation | E.12 Domain Separation, E.14 Least Functionality, E.19 Mediated Access |
| L3 | Suricata IDS with a curated MQTT/IoT ruleset | E.1 Anomaly Detection, E.3 Commensurate Protection, E.25 Reduced Complexity |
| L4 | Fail2ban reactive blocking via iptables | E.23 Protective Failure, E.24 Protective Recovery |

The complete protective stack idles at approximately **60 MB of RAM** — around 3% of a 2 GB Raspberry Pi 4.

---

## Quick start

Requires Docker and Docker Compose. Verified on Docker Desktop for Windows (WSL 2 backend) and on Linux.

```bash
git clone https://github.com/Rayyy-dev/Optimized-Defense-in-Depth-IOT.git
cd Optimized-Defense-in-Depth-IOT
docker compose up -d
docker compose ps
```

Seven containers should be running: `mqtt-broker`, `iot-sensor-1`, `iot-sensor-2`, `firewall`, `suricata`, `fail2ban`, and `attacker`.

---

## Repository layout

```
.
├── docker-compose.yml          # full container topology
├── configs/                    # broker config, ACL, password file
│   ├── acl
│   ├── mosquitto.conf
│   └── passwd
├── scripts/
│   ├── firewall.sh             # L2 firewall iptables rules
│   └── sensor.py               # simulated IoT device (paho-mqtt publisher)
├── firewall/                   # Dockerfile and entrypoint for the L2 firewall
│   ├── Dockerfile
│   └── entrypoint.sh
├── suricata/                   # L3 IDS image and ruleset
│   ├── Dockerfile
│   ├── local.rules
│   └── suricata.yaml
├── fail2ban/                   # L4 reactive blocker
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── jail.local
│   └── suricata-filter.conf
└── logs/                       # runtime logs
    ├── mosquitto/
    └── suricata/
```

---

## Architecture

```
External Network                  Edge Gateway                       Internal Network
+----------------+      attack    +-----------------+   inspects    +-------------------+
|                |   ---------->  |  L2 Firewall    | ............> |   L3 Suricata IDS |
|   Adversary    |                |  (iptables +    |                |   (curated rules) |
|   (Kali)       |                |   socat :1883)  | <-- alerts -- |                   |
+----------------+                +-----------------+               +-------------------+
                                       ^   |                                    |
                                       |   | TCP 1883 allowed                   v
                                       |   v                            +---------------+
                                +-----------------+                     |   L4 Fail2ban  |
                                | L1 Broker (ACL) |                     |   (iptables    |
                                | Mosquitto       |                     |    bans)       |
                                +-----------------+                     +---------------+
                                       ^   ^
                                       |   |  publish (authenticated)
                                +-----------------+
                                | temp-1 sensor   |
                                | motion-1 sensor |
                                +-----------------+
```

The firewall and IDS share a network namespace, which is the most direct way in Docker to place inspection on the same path observed by the firewall. Fail2ban joins the same namespace so its iptables rules act on that path as well.

---

## Attack scenarios

Open a shell in the attacker container and install the required tooling:

```bash
docker exec -it attacker bash
apt update && apt install -y nmap mosquitto-clients
```

### Reconnaissance scan

```bash
nmap -p 22,80,443,1883,8080,8883 -Pn firewall
```

Expected result: only port `1883` reports as open; all other ports report as `filtered`.

### Anonymous eavesdropping attempt

```bash
mosquitto_sub -h firewall -p 1883 -t "#" -v
```

Expected result: `Connection error: Connection Refused: not authorised.`

### Unauthorized topic access with compromised credentials

```bash
mosquitto_sub -h firewall -p 1883 -t "#" -v -u temp-1 -P TempPass123
```

Expected result: the connection is accepted, but the broker silently denies the subscription because the ACL blocks read access. Suricata additionally flags the wildcard subscribe attempt.

### Verifying Fail2ban enforcement

Exit the attacker container, then run:

```bash
docker exec suricata cat /var/log/suricata/fast.log
docker exec fail2ban fail2ban-client status suricata
```

Suricata alerts should be visible and one IP should appear in the banned list. The same source IP can no longer reach the broker — port 1883 now reports as `filtered`, and new MQTT connections time out.

---

## Teardown

```bash
docker compose down
```

This removes the containers and the two user-defined Docker networks. Persistent files such as configs and logs remain on disk.

---

## Scope and limitations

The following limitations are intentional and discussed in the accompanying report:

- **TLS is disabled on the broker.** This was a deliberate choice to allow the access-control behavior to be observed without the encryption layer obscuring it. Any production deployment must use MQTT over TLS with mutual authentication.
- **Quantitative measurements are limited.** Resource footprint was recorded only on an idle stack; performance under sustained attack load was not measured.
- **The Suricata ruleset is intentionally small** (four hand-written rules tailored to this testbed). A production deployment should extend it with a curated subset of Emerging Threats Open rules relevant to IoT and MQTT.
- **The attack set is intentionally small** (four scenarios), chosen to exercise each layer. Evasion techniques such as low-and-slow scans or MQTT-over-WebSocket are out of scope.

---

## Reference

Ross, R., McEvilley, M., & Winstead, M. (2022). *Engineering trustworthy secure systems* (NIST Special Publication 800-160 Volume 1 Revision 1). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-160v1r1

---

## Course information

| | |
|---|---|
| Course | Security and Continuity of Computer Systems |
| Institution | Akademia WSB, Katowice |
| Supervisor | Prof. Adrian Kapczyński |
| Author | Areeha Usman (58527) |

---

## License

This repository contains academic coursework. The code may be freely read, studied, and adapted. Attribution to this repository is appreciated where portions are reused.
