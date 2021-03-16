# Installation of zabbix-agent
**OS**: Linux (any)

**Architecture**: ppc64le

**Binaries**: [Zabbix Downloads](https://www.zabbix.com/download_agents?version=5.0+LTS&release=5.0.9&os=Linux&os_version=Any&hardware=ppc64le&encryption=No+encryption&packaging=Archive)

## Contents
* zabbix_agent
* readme.md
* zabbix_agent-5.0.8-linux-ppc64le.tar
  * This sould propably be in GitHub releases
* zabbix-install
* zabbix-uninstall

### zabbix_agent
* **bin/**
  * zabbix_get
  * zabbix_sender
* **conf/**
  * /scripts
    * external scripts
  * /zabbix_agentd
    * external script configuration files
* **sbin/**
  * zabbix_agentd
* **zabbix-agent-init** (deprecated?)
  * init script for /etc/init.d
* **zabbix-agent.service**
  * systemd service file, used to run agent as a service

## Creation of installation package
**Compress the zabbix_agent directory** \
`tar -zxvf zabbix_agent-5.0.8-linux-ppc64le.tar.gz zabbix_agent`

Deliver the contents of `archive/` directory.


## Operating the agent
**Reload the service files to include the new service after installation.** \
`sudo systemctl daemon-reload`

**Start zabbix-agent service** \
`sudo systemctl start zabbix-agent.service`

**Start zabbix-agent service** \
`sudo systemctl stop zabbix-agent.service`

**To check the status of zabbix-agent** \
`sudo systemctl status zabbix-agent.service`

**To enable zabbix-agent on every reboot** \
`sudo systemctl enable zabbix-agent.service`

**To disable zabbix-agent on every reboot** \
`sudo systemctl disable zabbix-agent.service`
