#!/bin/bash

###########################################################
# WAZUH-VT-THREATCHECK
# Command Reference
# Author: Senha Fathima
###########################################################

#############################
# Clone Wazuh Docker
#############################

git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.0

cd wazuh-docker/single-node

#############################
# Generate Certificates
#############################

docker compose -f generate-indexer-certs.yml run --rm generator

#############################
# Deploy Wazuh
#############################

docker compose up -d

docker ps

#############################
# Verify Docker
#############################

docker version

#############################
# Install Wazuh Agent
#############################

WAZUH_MANAGER="127.0.0.1" sudo apt install wazuh-agent -y

sudo systemctl enable wazuh-agent

sudo systemctl start wazuh-agent

sudo /var/ossec/bin/wazuh-control status

#############################
# Restart Agent
#############################

sudo systemctl restart wazuh-agent

#############################
# Restart Manager
#############################

docker exec -it single-node-wazuh.manager-1 \
/var/ossec/bin/wazuh-control restart

#############################
# Test File Integrity Monitoring
#############################

sudo touch /tmp/testfile.txt

sudo rm /tmp/testfile.txt

#############################
# Download EICAR Test File
#############################

curl -o /tmp/eicar.com.txt \
https://secure.eicar.org/eicar.com.txt

#############################
# Test AlienVault Integration
#############################

docker exec -it single-node-wazuh.manager-1 /bin/bash -c \
'echo "{\"data\":{\"srcip\":\"198.51.100.10\"}}" | \
python3 /var/ossec/integrations/custom-alienvault.py'

#############################
# Verify Active Response
#############################

sudo grep "firewall-drop" \
/var/ossec/logs/active-responses.log

#############################
# Useful Logs
#############################

docker logs single-node-wazuh.manager-1

sudo tail -f /var/ossec/logs/active-responses.log

sudo tail -f /var/ossec/logs/ossec.log
