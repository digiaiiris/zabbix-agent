# Zabbix Agent (Iiris)
**OS**: Linux (any)

**Architecture**: ppc64le

**Binaries**: [Zabbix Downloads](https://www.zabbix.com/download_agents?version=5.0+LTS&release=5.0.10&os=Linux&os_version=Any&hardware=ppc64le&encryption=No+encryption&packaging=Archive)

## Contents
* externalscripts
  * directory for external scripts that are extracted to agent via build
* externalconf
  * directory for external configurations that are extracted to agent via build
* build.sh
  * build script that repacks archive downloaded from zabbix.com
  * imports external scripts and configurations from local exteranconf and externalscripts directories
* options.cfg
  * configuration file for downloading agent from zabbix.com
  * contains basic zabbix-agent configurations
* readme.md
* zabbix-agent.service
  * service file for systemd
* zabbix-install
  * install script that extracts zabbix-agent files and creates local user and group for zabbix
* zabbix-uninstall

## Build installation package
1. Edit agent configurations in options.cfg
2. Run command \
`./build.sh`
3. Deliver the package
4. Extract it with \
`tar -zxvf zabbix_agent-<version>-linux-ppc64le-installation.tar.gz`
5. Run installation script with sudo \
`sudo ./zabbix-install`
6. Remove agent with \
`sudo ./zabbix-uninstall`

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
