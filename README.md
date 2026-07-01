# Wazuh-VT-ThreatCheck

A Security Information and Event Management (SIEM) project demonstrating real-time threat detection, threat intelligence enrichment, File Integrity Monitoring (FIM), and automated incident response using Wazuh, VirusTotal, and AlienVault OTX.

---

## Overview

This project implements a complete Wazuh-based monitoring environment deployed using Docker on Kali Linux. It integrates multiple security technologies to detect malicious activity, enrich alerts with external threat intelligence, map attacks to the MITRE ATT&CK framework, and automatically respond to confirmed threats.

The environment was validated using the EICAR malware test file to simulate malware detection and verify the complete incident response workflow.

---

## Features

- Wazuh SIEM deployment using Docker
- Wazuh Agent configuration
- File Integrity Monitoring (FIM)
- VirusTotal integration
- AlienVault OTX integration
- MITRE ATT&CK mapping
- Active Response (firewall-drop)
- Threat Hunting dashboard
- EICAR malware detection

---

## Technology Stack

| Component | Version |
|-----------|---------|
| Operating System | Kali Linux 2026.2 |
| Wazuh | 4.14.0 |
| Docker Engine | 29.6.0 |
| Python | 3.x |
| VirusTotal API | Free Tier |
| AlienVault OTX | Community Edition |

---

## Project Workflow

1. Install Docker Engine
2. Deploy Wazuh Stack
3. Configure Wazuh Agent
4. Configure File Integrity Monitoring
5. Integrate VirusTotal
6. Integrate AlienVault OTX
7. Configure MITRE ATT&CK
8. Configure Active Response
9. Validate using EICAR
10. Review alerts in the Threat Hunting Dashboard

---

## Repository Contents

```
report/
    WAZUH-VT-THREATCHECK.pdf

commands.sh
    Complete command reference used throughout the project.

scripts/
    Custom AlienVault integration script (if included).
```

---

## Report

The complete implementation guide, configuration steps, screenshots, testing procedures, and results are available in:

```
report/WAZUH-VT-THREATCHECK.pdf
```

---

## Skills Demonstrated

- Security Monitoring
- SIEM Deployment
- Threat Intelligence
- Incident Response
- Docker Administration
- Linux Administration
- File Integrity Monitoring
- Threat Hunting
- MITRE ATT&CK
- Malware Detection
- Log Analysis

---

## Security Notice

Sensitive information has been removed from this repository, including:

- API Keys
- Email Addresses
- Passwords
- Authentication Tokens

Placeholder values are used where appropriate.

---

## References

- Wazuh Documentation
- VirusTotal Documentation
- AlienVault OTX Documentation
- MITRE ATT&CK Framework
- EICAR Anti-Malware Test File

---

## Author

**Senha Fathima**

Cybersecurity Student | SOC Analyst Enthusiast
