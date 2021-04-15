set -e

source ./options.cfg

on_error() {
    echo 'Encountered unexpected error... cleaning up'
    rm -rf zabbix_build
}

trap 'on_error' ERR

echo "Downloading official agent archive"
wget -O "zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz" "https://cdn.zabbix.com/zabbix/binaries/stable/5.0/$ZABBIX_VERSION/zabbix_agent-$ZABBIX_VERSION-linux-ppc64le-static.tar.gz"

echo "Creating temporary directory"
mkdir -p zabbix_build
tar --no-same-owner --strip-components=1 --no-overwrite-dir -C zabbix_build -zxvf "zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz"

echo "Creating external scripts directory"
mkdir zabbix_build/etc/zabbix/scripts

echo "Renaming externalconf directory"
mv zabbix_build/etc/zabbix/zabbix_agentd.conf.d zabbix_build$EXTERNALCONF

echo "Configuring agent based on options.cfg"
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ACTIVE_HOST/g" zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/# Hostname=Zabbix server/g" zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i "s/# StartAgents=3/StartAgents=$START_AGENTS/g" zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i "s/# TLSConnect=unencrypted/TLSConnect=psk/g" zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i "s/# TLSPSKIdentity=/TLSPSKIdentity=$PSK_IDENTITY/g" zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i 's/# TLSPSKFile=/TLSPSKFile='"$(echo "$PSK_FILE" | sed -e 's/[/.&]/\\&/g')"'/g' zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i 's/# PidFile=\/tmp\/zabbix_agentd\.pid/PidFile='"$(echo "$PID_FILE" | sed -e 's/[/.&]/\\&/g')"'/g' zabbix_build/etc/zabbix/zabbix_agentd.conf
sed -i 's/LogFile=\/tmp\/zabbix_agentd\.log/LogFile='"$(echo "$LOG_FILE" | sed -e 's/[/.&]/\\&/g')"'/g' zabbix_build/etc/zabbix/zabbix_agentd.conf

echo "Include=$EXTERNALCONF*.conf" >> zabbix_build/etc/zabbix/zabbix_agentd.conf

echo "Copying custom scripts to package and giving execute permissions"
cp -a externalscripts/. zabbix_build/etc/zabbix/scripts/
cp -a externalconf/. zabbix_build$EXTERNALCONF
chmod +x zabbix_build/etc/zabbix/scripts/*

echo "Adding psk file"
cp psk.key zabbix_build/etc/zabbix/
chmod 600 zabbix_build/etc/zabbix/psk.key

echo "Repacking..."
tar -czvf zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz zabbix_build
tar -czvf zabbix_agent-$ZABBIX_VERSION-linux-ppc64le-installation.tar.gz zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz zabbix-install zabbix-uninstall options.cfg zabbix-agent.service

echo "Removing temporary build directory"
rm -rf zabbix_build

echo "Done"
echo ""
echo "Deliver package zabbix_agent-$ZABBIX_VERSION-linux-ppc64le-installation.tar.gz"
echo ""
echo "Extract package with command:"
echo "tar -zxvf zabbix_agent-$ZABBIX_VERSION-linux-ppc64le-installation.tar.gz"
echo ""
echo "Run installation with command"
echo "./zabbix-install"
