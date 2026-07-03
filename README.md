# Wazuh-VT-ThreatCheck

A Security Information and Event Management (SIEM) project demonstrating real-time threat detection, threat intelligence enrichment, File Integrity Monitoring (FIM), and automated incident response using Wazuh, VirusTotal, and AlienVault OTX.

---

##  Overview

This project demonstrates the deployment and configuration of **Wazuh SIEM v4.14.0** integrated with multiple threat intelligence tools for automated real-time threat detection, analysis, and incident response.

The entire stack runs on **Kali Linux 2026.2** using **Docker Engine 29.6.0**. The Wazuh Manager, Indexer, and Dashboard run inside Docker containers, while the **Wazuh Agent is installed directly on the Kali Linux host machine (BLACKICE)** — making the Kali host itself the monitored endpoint.

> ⚠️ **Endpoint Clarification:** The Wazuh Agent monitors the **Kali Linux host machine (BLACKICE)**, not the Docker containers. The agent communicates with the Wazuh Manager container over port 1514 on localhost (127.0.0.1).

---

##  Architecture

```text
┌─────────────────────────────────────────────────────────┐
│              Kali Linux 2026.2 — BLACKICE               │
│         AMD64 | 12 Cores | 7.5 GB RAM                   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Docker Engine 29.6.0                 │  │
│  │  ┌─────────────┐  ┌───────────┐  ┌────────────┐    │  │
│  │  │    Wazuh    │  │   Wazuh   │  │   Wazuh    │    │  │
│  │  │   Manager   │◄─►│  Indexer  │◄─►│ Dashboard  │    │  │
│  │  │ :1514/:1515 │  │   :9200   │  │   :443     │    │  │
│  │  └──────┬──────┘  └───────────┘  └────────────┘    │  │
│  └─────────┼─────────────────────────────────────────┘  │
│            │ port 1514 (localhost)                       │
│  ┌─────────▼───────────────────────────────────────┐    │
│  │           Wazuh Agent — BLACKICE                 │    │
│  │     Monitors the Kali Linux host machine         │    │
│  │     /etc | /usr/bin | /usr/sbin | /tmp           │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          │
            API calls from Wazuh Manager
              ┌───────────┼───────────┐
              ▼           ▼           ▼
   ┌──────────────┐ ┌───────────┐ ┌──────────────┐
   │  VirusTotal  │ │AlienVault │ │ MITRE ATT&CK │
   │     API      │ │  OTX API  │ │  Framework   │
   └──────────────┘ └───────────┘ └──────────────┘
```

## Integrations

| Integration | Purpose | Result |
|---|---|---|
| **VirusTotal** | File hash malware detection via API | EICAR detected by 65/67 engines — Rule 87105 |
| **AlienVault OTX** | IP reputation checks via custom Python script | OTX API queried successfully |
| **MITRE ATT&CK** | Automatic TTP mapping of alerts | T1565.001, T1203, T1078, T1548.003 |
| **File Integrity Monitoring** | Detect unauthorized file changes | Rule 550, 554 — /etc, /usr/bin, /tmp monitored |
| **Active Response** | Automated threat mitigation | firewall-drop triggered on Rule 87105 |

---

##  System Specifications

| Component | Details |
|---|---|
| Operating System | Kali Linux 2026.2 Rolling |
| Hostname | BLACKICE |
| Architecture | AMD64 (x86_64) |
| CPU | 12 Cores |
| RAM | 7.5 GB |
| Free Storage | 101 GB |
| Docker Version | 29.6.0 |
| Wazuh Version | 4.14.0 |

---

##  Deployment

All deployment commands are available in [`commands.sh`](./commands.sh)

### Quick Start

**1. Install Docker Engine**
```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo systemctl enable --now docker
```

**2. Clone Wazuh Docker Repository**
```bash
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.0
cd wazuh-docker/single-node/
```

**3. Generate SSL Certificates**
```bash
docker compose -f generate-indexer-certs.yml run --rm generator
```

**4. Deploy Wazuh Stack**
```bash
docker compose up -d
docker ps
```

**5. Access Dashboard**

URL      : https://localhost
Username : admin
Password : SecretPassword

**6. Install Wazuh Agent on Kali Host**
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
WAZUH_MANAGER="127.0.0.1" sudo apt install wazuh-agent -y
sudo systemctl enable --now wazuh-agent
```

---

##  Key Configurations

### File Integrity Monitoring
Add inside `<syscheck>` block in `/var/ossec/etc/ossec.conf` on the agent:
```xml
<directories>/etc,/usr/bin,/usr/sbin</directories>
<directories>/bin,/sbin,/boot</directories>
<directories>/tmp</directories>
<frequency>300</frequency>
```

### VirusTotal Integration
Add to Wazuh Manager ossec.conf:
```xml
<ossec_config>
  <integration>
    <name>virustotal</name>
    <api_key>YOUR_VIRUSTOTAL_API_KEY</api_key>
    <group>syscheck</group>
    <alert_format>json</alert_format>
  </integration>
</ossec_config>
```

### AlienVault OTX Integration
Deploy custom-alienvault.py inside the manager container:
```bash
docker cp custom-alienvault.py single-node-wazuh.manager-1:/var/ossec/integrations/
docker exec -it single-node-wazuh.manager-1 chmod +x /var/ossec/integrations/custom-alienvault.py
docker exec -it single-node-wazuh.manager-1 python3 -m pip install requests
```

Add to ossec.conf:
```xml
<ossec_config>
  <integration>
    <name>custom-alienvault</name>
    <hook_url></hook_url>
    <level>3</level>
    <alert_format>json</alert_format>
  </integration>
</ossec_config>
```

### Active Response
```xml
<ossec_config>
  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <rules_id>87105</rules_id>
    <timeout>600</timeout>
  </active-response>
</ossec_config>
```

---

## Results

| Module | Rule ID | Description | Status |
|---|---|---|---|
| File Integrity Monitoring | 550 | Integrity checksum changed | ✅ Detected |
| File Integrity Monitoring | 554 | File added to the system | ✅ Detected |
| VirusTotal | 87103 | VirusTotal queried — rate limit | ✅ Working |
| VirusTotal | 87105 | EICAR detected — 65/67 engines | ✅ Detected |
| MITRE ATT&CK | T1565.001 | Impact — Integrity checksum | ✅ Mapped |
| MITRE ATT&CK | T1203 | Execution — VirusTotal EICAR | ✅ Mapped |
| MITRE ATT&CK | T1078 | Defense Evasion, Persistence | ✅ Mapped |
| MITRE ATT&CK | T1548.003 | Privilege Escalation — Sudo | ✅ Mapped |
| Active Response | — | firewall-drop executed | ✅ Triggered |
| AlienVault OTX | — | IP reputation check returned | ✅ Working |

---

##  API Keys Required

| Service | Where to get |
|---|---|
| VirusTotal API Key | https://www.virustotal.com → Profile → API Key |
| AlienVault OTX API Key | https://otx.alienvault.com → Profile → API Key |

> **Security Note:** Never commit real API keys to GitHub. Always use placeholders in config files.

---

##  Known Limitations

- **VirusTotal free API** is limited to 4 requests per minute — this causes Rule 87103 to appear frequently. Rule 87105 fires when the rate limit is not exceeded.
- **Active Response firewall-drop** expects a srcip field. Since EICAR is a local file, no IP is blocked — but the response still executes and is logged.
- This is a **single-node deployment** suitable for learning and testing, not production use.

---

##  Author

**Senhafathima**
**Cybersecurity Student | SOC Analyst Enthusiast**
---

##  Disclaimer

This project is for **educational purposes only**. All testing was performed using safe simulated threats (EICAR test file). Do not use this setup in a production environment without proper security hardening.













