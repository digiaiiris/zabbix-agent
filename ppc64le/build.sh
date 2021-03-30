source ./options.cfg

echo "Downloading official agent archive"
wget -O "zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz" "https://cdn.zabbix.com/zabbix/binaries/stable/5.0/$ZABBIX_VERSION/zabbix_agent-$ZABBIX_VERSION-linux-ppc64le-static.tar.gz"

echo "Creating temporary directory"
mkdir -p zabbix_build
tar --no-same-owner --strip-components=1 --no-overwrite-dir -C zabbix_build -zxvf "zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz"

echo "Creating external scripts directory"
mkdir zabbix_build/etc/zabbix/scripts

echo "Modifying user permission for extraction"
chown -R zabbix:zabbix zabbix_build/etc/zabbix/*
chown -R root:root zabbix_build/usr/

echo "Configuring agent based on options.cfg"
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ACTIVE_HOST/g" zabbix_build/etc/zabbix/zabbix_agentd.conf

echo "Copying custom scripts to package"
mv externalscripts/* zabbix_build/etc/zabbix/scripts/
mv externalsconf/* zabbix_build/etc/zabbix/zabbix_agentd.conf.d/

echo "Adding systemd file"
mv zabbix_agent.service zabbix_build/

echo "Repacking..."
tar -czvf "zabbix_agent-$ZABBIX_VERSION-linux-ppc64le.tar.gz" zabbix_build
