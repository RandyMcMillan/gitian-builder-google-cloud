#!/usr/bin/env bash

#make default gitianuser work
me="$(whoami)"
su me
sudo ln -s /home/$me /home/gitianuser
cd /home/gitianuser
#REF: https://raw.githubusercontent.com/bitcoin-core/docs/master/gitian-building/gitian-building-setup-gitian-debian.md

#install for usage in this script
sudo apt-get install rename lynx
#begin setup
sudo apt-get install git ruby apt-cacher-ng qemu-utils debootstrap lxc python-cheetah parted kpartx bridge-utils make ubuntu-archive-keyring curl firewalld
echo "TYPE 'exit' then press RETURN"
sudo -s
# the version of lxc-start in Debian needs to run as root, so make sure
# that the build script can execute it without providing a password
echo "%sudo ALL=NOPASSWD: /usr/bin/lxc-start" > /etc/sudoers.d/gitian-lxc
echo "%sudo ALL=NOPASSWD: /usr/bin/lxc-execute" >> /etc/sudoers.d/gitian-lxc
# make /etc/rc.local script that sets up bridge between guest and host
echo '#!/bin/sh -e' > /etc/rc.local
echo 'brctl addbr br0' >> /etc/rc.local
echo 'ip addr add 10.0.3.1/24 broadcast 10.0.3.255 dev br0' >> /etc/rc.local
echo 'ip link set br0 up' >> /etc/rc.local
echo 'firewall-cmd --zone=trusted --add-interface=br0' >> /etc/rc.local
echo 'exit 0' >> /etc/rc.local
chmod +x /etc/rc.local
# make sure that USE_LXC is always set when logging in as gitianuser,
# and configure LXC IP addresses
echo 'export USE_LXC=1' >> /home/gitianuser/.profile
echo 'export GITIAN_HOST_IP=10.0.3.1' >> /home/gitianuser/.profile
echo 'export LXC_GUEST_IP=10.0.3.5' >> /home/gitianuser/.profile

#
wget http://archive.ubuntu.com/ubuntu/pool/universe/v/vm-builder/vm-builder_0.12.4+bzr494.orig.tar.gz
echo "76cbf8c52c391160b2641e7120dbade5afded713afaa6032f733a261f13e6a8e  vm-builder_0.12.4+bzr494.orig.tar.gz" | sha256sum -c
# (verification -- must return OK)
tar -zxvf vm-builder_0.12.4+bzr494.orig.tar.gz
cd vm-builder-0.12.4+bzr494
sudo python setup.py install
cd ..



read -p 'ENTER your Github.com username: ' GITHUB_USER_NAME
#read -sp 'Password: ' GITHUB_USER_PASSWORD
echo
echo Thankyou $GITHUB_USER_NAME we now have your login details
git clone https://github.com/bitcoin-core/gitian.sigs.git
cd gitian.sigs
git remote add $GITHUB_USER_NAME  https://github.com/$GITHUB_USER_NAME/gitian.sigs.git
cd ..

git clone https://github.com/devrandom/gitian-builder.git
git clone https://github.com/bitcoin/bitcoin
git clone https://github.com/bitcoin-core/gitian.sigs.git
git clone https://github.com/bitcoin-core/bitcoin-detached-sigs.git

cd gitian-builder
bin/make-base-vm --lxc --arch amd64 --suite bionic # For releases >= 0.17.0
bin/make-base-vm --lxc --arch amd64 --suite trusty # For releases <  0.17.0
cd /home/gitianuser
cp /home/gitianuser/bitcoin/contrib/gitian-build.py .


read -p 'Rebuild base? Y/n ' REBUILD
if [ $REBUILD == 'Y' ];then
	rm -rf /home/gitianuser/gitian-builder/base-*
	rm -drf /home/gitianuser/gitian-builder/inputs
fi

./gitian-build.py --setup
rm -f /home/gitianuser/vm-builder*.gz.*

mkdir /home/gitianuser/gitian-builder/inputs
rm -rf /home/gitianuser/MacOSX*
wget  https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.11.sdk.tar.xz
rename -v -f 's/.xz/.gz' MacOSX10.11.sdk.tar.xz
#wget -O /home/gitianuser/gitian-builder/inputs https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.12.sdk.tar.xz
#wget -O /home/gitianuser/gitian-builder/inputs https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.13.sdk.tar.xz
#mv /home/gitianuser/gitian-builder/inputs/MacOSX10.13.sdk.tar.xz /home/gitianuser/gitian-builder/inputs/
