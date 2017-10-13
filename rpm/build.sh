#/bin/bash
set -e

# Run this command only inside docker container with proper environment variables set
# (see usage in Dockerfile.* files)

# Get the SRPM containing Zabbix Official RPM packaging sources
wget -nv "$URL_ZABBIX_SRPM"
rpm -ih zabbix-*.src.rpm

# Get latest sources from Pulssi repository, including Pulssi changes
wget -nv https://github.com/digiapulssi/zabbix/tarball/$ZABBIX_BRANCH
mkdir zabbix-$ZABBIX_VERSION
tar zxf $ZABBIX_BRANCH -C zabbix-$ZABBIX_VERSION --strip 1
pushd zabbix-$ZABBIX_VERSION

# Default configuration changes
# Do not specify Hostname but use system hostname by default
sed -i '/^Hostname=Zabbix server/d' conf/zabbix_agentd.conf
# Bigger timeout
sed -i '/^# Timeout=3/a Timeout=15' conf/zabbix_agentd.conf

# Compile tarball so that it's identical to the one included in official SPRM
# See: https://www.zabbix.org/wiki/Compilation_instructions

# file paths are so close to 99 long that adding digiapulssi to version number makes them too long with old tar version
./bootstrap.sh
./configure
make dbschema
make css
make gettext
mkdir src/zabbix_java/bin # this is some workaround documented nowhere but necessary for make dist to work...
make dist
mkdir -p $RPMBUILD/SOURCES # required for CentOS 5 which doesn't have fedora-packager
rm $RPMBUILD/SOURCES/zabbix-$ZABBIX_VERSION.tar.gz # Original one installed by SRPM
mv zabbix-$ZABBIX_VERSION.tar.gz $RPMBUILD/SOURCES/
popd

# Get Pulssi monitoring scripts
mkdir -p /tmp/zabbix-monitoring-scripts
pushd /tmp/zabbix-monitoring-scripts
wget https://github.com/digiapulssi/zabbix-monitoring-scripts/tarball/master
tar -zxvf master */etc/zabbix/scripts --strip 3
tar -zxvf master */etc/zabbix/zabbix_agentd.d --strip 3
tar cvf $RPMBUILD/SOURCES/scripts.tar.gz scripts
cd zabbix_agentd.d
tar cvf $RPMBUILD/SOURCES/scripts_config.tar.gz .
popd


##############################################################33
# Update package name and version to SPEC

# Change name from zabbix-agent to zabbix-agent-pulssi
sed -i 's/^%package agent$/%package agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
# TBD ADD for Digia Pulssi to description
sed -i 's/^%description agent$/%description agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
sed -i 's/^%pre agent$/%pre agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
sed -i 's/^%post agent$/%post agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
sed -i 's/^%preun agent$/%preun agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
sed -i 's/^%postun agent$/%postun agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec
sed -i 's/^%files agent$/%files agent-pulssi/' $RPMBUILD/SPECS/zabbix.spec

# Change release/build number (3.2.3-X where X is build number)
sed -i 's/^\(Release:\s\+\)[0-9]\+%/\1'${PULSSI_RELEASE_VERSION}'%/' $RPMBUILD/SPECS/zabbix.spec

##############################################################33
# Monitoring scripts under /etc/zabbix/scripts

sed -i '/^Source15/a Source16:		scripts.tar.gz' $RPMBUILD/SPECS/zabbix.spec
sed -i '/^%prep/a %setup -T -b 16 -q -n scripts' $RPMBUILD/SPECS/zabbix.spec

# install section
sed -i '/^%clean/i # install monitoring scripts \
cp -r ../scripts $RPM_BUILD_ROOT%{_sysconfdir}/zabbix/ \
chmod 0755 $RPM_BUILD_ROOT%{_sysconfdir}/zabbix/scripts/* \
' $RPMBUILD/SPECS/zabbix.spec

# %files agent section
sed -i '/^%dir %{_sysconfdir}\/zabbix\/zabbix_agentd.d/i %dir %{_sysconfdir}/zabbix/scripts' $RPMBUILD/SPECS/zabbix.spec
# Add each script file individually to files section
for scriptpath in scripts/*; do
   scriptfile=$(basename $scriptpath)
   sed -i '/^%dir %{_sysconfdir}\/zabbix\/scripts/a %config(noreplace) %{_sysconfdir}/zabbix/scripts/'${scriptfile} $RPMBUILD/SPECS/zabbix.spec
done

##############################################################33
# Monitoring script configuration files under /etc/zabbix/zabbix_agentd.d

sed -i '/^Source16/a Source17:		scripts_config.tar.gz' $RPMBUILD/SPECS/zabbix.spec
sed -i '/^%setup -T -b 16/a %setup -T -a 17 -q -c -n zabbix_agentd.d' $RPMBUILD/SPECS/zabbix.spec

# install section
sed -i '/^%clean/i # install monitoring script configuration files \
cp ../zabbix_agentd.d/* $RPM_BUILD_ROOT%{_sysconfdir}/zabbix/zabbix_agentd.d/ \
chmod 0644 $RPM_BUILD_ROOT%{_sysconfdir}/zabbix/zabbix_agentd.d/* \
' $RPMBUILD/SPECS/zabbix.spec

# %files agent section
# Add each configuration file individually to files section
for confpath in config/*; do
   conffile=$(basename $confpath)
   sed -i '/^%dir %{_sysconfdir}\/zabbix\/zabbix_agentd.d/a %config(noreplace) %{_sysconfdir}/zabbix/zabbix_agentd.d/'${conffile} $RPMBUILD/SPECS/zabbix.spec
done

# Disable python build by rpmbuild (taken from https://www.redhat.com/archives/rpm-list/2007-November/msg00020.html)
# Python build would mess with Python monitoring scripts
sed -i '/^#!\/bin\/bash/a exit 0' /usr/lib/rpm/brp-python-bytecompile

# Build the rpm package
if type rpmbuild-md5 >/dev/null 2>&1; then
   rpmbuild-md5 -bb $RPMBUILD/SPECS/zabbix.spec
else
   # CentOS 5 doesn't have fedora-package which would include rpmbuild-md5
   rpmbuild -bb $RPMBUILD/SPECS/zabbix.spec
fi
