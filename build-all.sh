#!/bin/bash
set -e

RENAME=rename
if [ -f /etc/redhat-release ]; then
  # We're depending or Perl version of rename that ships by default in Debian-based distros but not in CentOS/Redhat
  RENAME=/usr/local/bin/rename
  if [ ! -f $RENAME ]; then
    sudo yum install perl-CPAN
    sudo cpan<<EOF
      install Module::Build
      install File::Rename
EOF
  fi
fi

pushd rpm

# First clear old packages
sudo rm -fr RPMS/*

# First build the package creation containers locally
docker build -t zabbix-rpm:centos6 -f Dockerfile.centos6 .
docker build -t zabbix-rpm:centos7 -f Dockerfile.centos7 .
docker build -t zabbix-rpm:centos8 -f Dockerfile.centos8 .

# Run the following commands to produce new installation packages for different platforms
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos6
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos7
#docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos8

# Remove "centos" from CentOS 7 package name
sudo $RENAME 's/zabbix-agent-iiris-([0-9.-]+)\.(el[\d])\.centos\.x86_64\.rpm/zabbix-agent-iiris-$1.$2.x86_64.rpm/' RPMS/x86_64/*.rpm

popd

pushd debian

# First build the package creation containers locally
docker build -t zabbix-deb:debian8 -f Dockerfile.debian8 .
docker build -t zabbix-deb:debian9 -f Dockerfile.debian9 .
docker build -t zabbix-deb:debian10 -f Dockerfile.debian10 .
#docker build -t zabbix-deb:debian8docker -f Dockerfile.debian8.docker-host-monitoring .

# Then run the following commands to produce new installation packages for different platforms
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian8
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian9
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian10
#docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian8docker

popd


echo "--------------"
echo "BUILD COMPLETE"
echo "--------------"

echo "Upload the following zabbix-agent rpm packages to Github releases:"
ls -la rpm/RPMS/x86_64/zabbix-agent*.rpm
ls -la debian/DEB/zabbix-agent*.deb
