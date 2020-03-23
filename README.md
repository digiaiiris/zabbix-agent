# Overview

Build Digia Iiris specific Zabbix Agent installation packages. The changes introduced by Iiris are as follows:

- Use a forked Zabbix agent at https://github.com/digiaiiris/zabbix. The changes in the forked version
  enable new security features that allow better control at the monitored host as to the files and
  logs monitored
- Bundle monitoring scripts at https://github.com/digiapulssi/zabbix-monitoring-scripts
- Default configuration does not define hostname but takes it from system hostname
- Default configuration defines Timeout of 15 seconds (instead of default 3 seconds)

# Download

Download the latest installation packages from https://github.com/digiaiiris/zabbix-agent/releases/latest

- CentOS / RedHat / Oracle Linux 6.x / Amazon Linux v1 (AMI versions 2017.09 or earlier): zabbix-agent-iiris-VERSION.el6.x86_64.rpm
- CentOS / RedHat / Oracle Linux 7.x / Amazon Linux v2 (AMI versions 2017.12 onwards): zabbix-agent-iiris-VERSION.el7.x86_64.rpm
- Debian 8 (Jessie): zabbix-agent-iiris_VERSION.jessie-1_amd64.deb
- Debian 9 (Stretch): zabbix-agent-iiris_VERSION.stretch-1_amd64.deb
- Debian 10 (Buster): zabbix-agent-iiris_VERSION.buster-1_amd64.deb

# Installation and Configuration

### Installation over Existing Zabbix Agent Installation

In case you already have the official Zabbix Agent installed on your system,
you should uninstall it before installing digiaiiris version.

```
yum erase zabbix-agent (CentOS / RedHat / Orace Linux / Amazon Linux)
apt-get purge zabbix-agent (Debian)
```

### Installation on CentOS / RedHat / Oracle Linux / Amazon Linux

Install the downloaded RPM package with the following command:

```
yum localinstall zabbix-agent-iiris-VERSION.DISTRIBUTION.x86_64.rpm
(for CentOS/RedHat/Oracle Linux 5.x you need to add --nogpgcheck flag)
```

### Installation on Debian

Install the downloaded DEB package either with `apt`, `dpkg -i` or `gdebi` command:

Alternative 1 (for Debian 9 "Stretch" and above).
Use `apt` that installs dependencies automatically:
```
apt install ./zabbix-agent-iiris_VERSION.DISTRIBUTION-1_amd64.deb
```

Alternative 2: Use `dpkg -i` and install dependencies manually:
```
dpkg -i zabbix-agent-iiris_VERSION.DISTRIBUTION-1_amd64.deb
(the command shows missing dependencies as `Package nnn not installed`)
apt-get install --fix-broken
(this will install the missing dependencies and finish zabbix-agent-iiris package installation)
```

Alternative 3: Use `gdebi` that installs dependencies automatically:

```
apt-get update
apt-get install gdebi
gdebi zabbix-agent-iiris_VERSION.DISTRIBUTION-1_amd64.deb
```

*Note* with older Debians (Jessie and Stretch), see separate notes below.

### Agent Configuration

After installation, you should configure the following sections in /etc/zabbix/zabbix_agentd.conf file.
Find the current configuration lines and replace them as follows:
```
(Under Passive checks related)
Server=ZABBIX_SERVER_SOURCE_ADDRESS1,ZABBIX_SERVER_SOURCE_ADDRESS2

(Under Active checks related)
ServerActive=ZABBIX_SERVER_DEST_ADDRESS
```

In elevated security level systems (Vahti korotettu) you should configure all
the allowed monitored files under AllowedPath setting. The files configured must
not contain sensitive (ST III) information.

```
(Under ADVANCED CONTROL OVER FILES)
AllowedPath=REGEXP_PATH_TO_FILE1
AllowedPath=REGEXP_PATH_TO_FILE2
AllowedPath=ITEMTYPE,REGEXP_PATH_TO_FILE3 (supported from version 3.4.4-0 onwards)

To allow monitoring of all files under /var/log/example/:
AllowedPath=^/var/log/example/.*$

To allow only log.count monitoring item for files under /var/log/example2/:
AllowedPath=log.count,^/var/log/example2/.*$
```

### Service Configuration

After the agent has been configured, restart the service and configure it to auto-start on boot as follows:

CentOS / RedHat / Oracle Linux / Amazon Linux:
```
service zabbix-agent restart
chkconfig zabbix-agent on
```

Debian:
```
service zabbix-agent restart
systemctl enable zabbix-agent
```

### Docker Swarm service monitoring

# Installing Python

In order to use Docker Swarm service monitoring, it is required to install
Python and needful libraries for monitoring. Python is usually available on
Linux distributions. If it is not present on your target system, there are
several online installation documentations available. For instance, one good
documentation is Real Python's installation & setup guide located here:
https://realpython.com/installing-python/

# Installing required libraries

For Python version 3, install dependencies using pip:
```
pip3 install docker requests urllib3 python-dateutil
```

For Python version 2, install specific versions of libraries:
```
pip install docker==2.7.0 requests==2.23.0 urllib3==1.24.3 python-dateutil==2.8.1
```

Add user "zabbix" to group "docker":
```
sudo usermod -aG docker zabbix
```


### Notes with Older Debians (Jessie and Stretch)

#### libssl

Debian Jessie and Stretch versions no longer support libssl1.1.0. Download the correct file (eg. `libssl1.1_1.1.0l-1~deb9u1_amd64.deb`)
from http://security-cdn.debian.org/debian-security/pool/updates/main/o/openssl/
and install it manually before installing the agent.

#### Ubuntu Trusty (14.04): libpcre3 library

Zabbix Agent version 3.4.4 (or later) requires libpcre3 version 8.35 as its dependency.
Ubuntu Trusty however has only version 8.31 available by default.
To install Zabbix Agent on Ubuntu Trusty you need to first install libpcre3 version 8.35 manually.

* Pick up the correct architecture and mirror at https://packages.debian.org/jessie/libpcre3
* Download the installation package and install it using dpkg or gdebi

```
(required only for Ubuntu Trusty)
# amd64 architecture selected as an example
curl -OJ http://ftp.fi.debian.org/debian/pool/main/p/pcre3/libpcre3_8.35-3.3+deb8u4_amd64.deb
dpkg -i libpcre3_8.35-3.3+deb8u4_amd64.deb

# Verify libpcre3 version number (should show 8.35)
dpkg -s libpcre3
```


# Troubleshooting

Zabbix agent log is located by default in /var/log/zabbix/zabbix_agentd.log.
Check for the following lines which indicate connection problems:

```
84:20170704:065535.728 active check configuration update from [ZABBIX_SERVER_DEST_ADDRESS:10051] started to fail (cannot connect to [[ZABBIX_SERVER_DEST_ADDRESS]:10051]: [111] Connection refused
```

The next line indicates that connection works but the host is not yet configured in Digia Iiris side:
```
64:20170704:071034.703 no active checks on server [ZABBIX_SERVER_DEST_ADDRESS:10051]: host [HOSTNAME] not found
```

Firewall openings for active checks can be checked with one of the following tools, depending on your system:
```
telnet ZABBIX_SERVER_DEST_ADDRESS 10051
nc -zv ZABBIX_SERVER_DEST_ADDRESS 10051

# Without any additional tools (from bash):
# The command should run 1-2 seconds and then exit with status code 0.
# If firewall openings are not ok the command runs 1-2 minutes and then prints Connection timed out.
cat < /dev/tcp/ZABBIX_SERVER_DEST_ADDRESS/10051; echo $?
```

# Installation of Custom Monitoring Scripts

Sometimes you need to install custom monitoring scripts to your host.
A custom monitoring script consists of a script file and a configuration files.
Install the files to the following locations:

- Script file: /etc/zabbix/scripts
- Configuration file (something.conf): /etc/zabbix/zabbix-agentd.d/

Modify the file permissions as follows (the owner should be root):

```
chmod 0755 /etc/zabbix/scripts/SCRIPTNAME
chmod 0644 /etc/zabbix/zabbix-agentd.d/SCRIPTNAME.conf
```

NOTE! Do not leave any backup files etc. under /etc/zabbix/zabbix-agend.d/ because
all the files in the directory are considered as actual configuration files and loaded by Zabbix Agent.

# How to Release a New Version (for Digia Iiris Developers)

Update IIRIS_RELEASE_VERSION in Dockerfile files (see below).

Run the build script in the repository root directory:

```
./build-all.sh
```

After building the release, create a new release in Github and upload the packages there.

# Implementation Notes

The packaging has been adapted from the instructions at http://zabbix.org/wiki/Docs/howto/rebuild_rpms

# Versioning Practices

Environment variables controlling the versions are defined in Dockerfile.* files.

IIRIS_RELEASE_VERSION environment variable defines Digia Iiris release/build number
eg. 3.2.3-IIRIS_RELEASE_VERSION.

To release a package based on a newer Zabbix Agent version:

- Update ZABBIX_VERSION
- Set IIRIS_RELEASE_VERSION to 0
- Update URL_ZABBIX_SRPM

To release a newer Digia Iiris specific Zabbix Agent version using the same Zabbix Agent version than before:

- Increase IIRIS_RELEASE_VERSION by 1
