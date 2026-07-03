#!/bin/bash
# =============================================================================
# Wazuh-VT-ThreatCheck — Deployment and Configuration Commands
# OS: Kali Linux 2026.2 | Docker Engine 29.6.0 | Wazuh v4.14.0
# Author: Senhafathimaa
# =============================================================================

# =============================================================================
# PHASE 1 — Docker Engine Installation
# =============================================================================

sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release -y

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian bookworm stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker version
docker info

# =============================================================================
# PHASE 2 — Clone Wazuh Repository and Generate Certificates
# =============================================================================

sudo apt install git -y

git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.0
cd wazuh-docker/single-node/

# If port 9200 is already in use stop Elasticsearch first
sudo systemctl stop elasticsearch
sudo systemctl disable elasticsearch

# Generate SSL certificates
docker compose -f generate-indexer-certs.yml run --rm generator

# =============================================================================
# PHASE 3 — Deploy Wazuh
# =============================================================================

docker compose up -d
docker ps

# Access dashboard at https://localhost
# Username: admin | Password: SecretPassword

# =============================================================================
# PHASE 4 — Wazuh Agent Installation on Kali Host
# =============================================================================

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update

WAZUH_MANAGER="127.0.0.1" sudo apt install wazuh-agent -y
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Verify
sudo systemctl status wazuh-agent
sudo /var/ossec/bin/wazuh-control status

# =============================================================================
# PHASE 5 — File Integrity Monitoring (FIM)
# =============================================================================

# Edit /var/ossec/etc/ossec.conf on the agent
# Add inside <syscheck> block:
# <directories>/etc,/usr/bin,/usr/sbin</directories>
# <directories>/bin,/sbin,/boot</directories>
# <directories>/tmp</directories>
# <frequency>300</frequency>

sudo systemctl restart wazuh-agent

# Test FIM
sudo touch /tmp/testfile.txt
sudo rm /tmp/testfile.txt

# =============================================================================
# PHASE 6 — VirusTotal Integration
# =============================================================================

# Copy ossec.conf from manager container for editing
sudo docker cp single-node-wazuh.manager-1:/var/ossec/etc/ossec.conf /tmp/wazuh-ossec.conf
sudo chmod 777 /tmp/wazuh-ossec.conf

# Add VirusTotal block before last </ossec_config>:
# <ossec_config>
#   <integration>
#     <name>virustotal</name>
#     <api_key>YOUR_VIRUSTOTAL_API_KEY_HERE</api_key>
#     <group>syscheck</group>
#     <alert_format>json</alert_format>
#   </integration>
# </ossec_config>

# Copy back and restart
docker cp /tmp/wazuh-ossec.conf single-node-wazuh.manager-1:/var/ossec/etc/ossec.conf
docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart

# Test with EICAR file
curl -o /tmp/eicar.com.txt https://secure.eicar.org/eicar.com.txt

# =============================================================================
# PHASE 7 — AlienVault OTX Integration
# =============================================================================

# Copy OTX script into manager container
docker cp custom-alienvault.py single-node-wazuh.manager-1:/var/ossec/integrations/custom-alienvault.py
docker exec -it single-node-wazuh.manager-1 chmod +x /var/ossec/integrations/custom-alienvault.py

# Install requests module
docker exec -it single-node-wazuh.manager-1 python3 -m ensurepip
docker exec -it single-node-wazuh.manager-1 python3 -m pip install requests

# Test OTX
docker exec -it single-node-wazuh.manager-1 /bin/bash -c \
'echo "{\"data\":{\"srcip\":\"198.51.100.10\"},\"rule\":{\"id\":\"100010\",\"level\":10},\"full_log\":\"test\"}" | \
python3 /var/ossec/integrations/custom-alienvault.py'

# Add OTX block to ossec.conf and restart (same process as VirusTotal)
# <ossec_config>
#   <integration>
#     <name>custom-alienvault</name>
#     <hook_url></hook_url>
#     <level>3</level>
#     <alert_format>json</alert_format>
#   </integration>
# </ossec_config>

docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart

# =============================================================================
# PHASE 8 — MITRE ATT&CK (Built-in Wazuh)
# =============================================================================

# Generate MITRE alerts
whoami
id
cat /etc/passwd
netstat -an
ps aux

# View in dashboard: MITRE ATT&CK → Overview → Filter by BLACKICE

# =============================================================================
# PHASE 9 — Active Response
# =============================================================================

# Add to ossec.conf in manager container:
# <ossec_config>
#   <active-response>
#     <command>firewall-drop</command>
#     <location>local</location>
#     <rules_id>87105</rules_id>
#     <timeout>600</timeout>
#   </active-response>
# </ossec_config>

docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart

# Trigger Active Response
curl -o /tmp/eicar-test.com.txt https://secure.eicar.org/eicar.com.txt

# Verify Active Response executed
sudo grep "firewall-drop" /var/ossec/logs/active-responses.log

# =============================================================================
# VERIFICATION COMMANDS
# =============================================================================

docker ps
docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control status
sudo /var/ossec/bin/wazuh-control status
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/active-responses.log
