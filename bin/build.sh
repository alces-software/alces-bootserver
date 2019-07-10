#!/bin/bash

#Script to make the required packages that are needed for a 
#tftpboot server which isn't dependent on upstream provided 
#libraries, i.e. mostly built statically, or only requiring 
#the most common libraries and thus should be somewhat 
#portable onto other RHEL systems for now.

#Collect archives required to build services.

BASEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
source $BASEPATH/../etc/vars
#Ensure we die if anything breaks from here on in.
set -e
trap 'echo Could not build alces-bootserver, check logs.' ERR

if [ -z $INSTALLDIR ] ; then
  echo "Installation directory is not set in vars file."
  exit 1
fi

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
rm -rf ${INSTALLDIR}/build #!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#Install build utils
yum -y -e0 groupinstall "Development Tools"
yum -y -e0 install glibc-static syslinux wget

mkdir -p ${INSTALLDIR}/{bin,etc,var,libexec,build,tftpboot,resources} && cd ${INSTALLDIR}/build

#isc-dhcp server
wget ftp://ftp.isc.org/isc/dhcp/4.4.1/dhcp-4.4.1.tar.gz
#HPA's TFTP server
wget https://git.kernel.org/pub/scm/network/tftp/tftp-hpa.git/snapshot/tftp-hpa-5.2.tar.gz
#Node.js
wget https://nodejs.org/dist/v12.5.0/node-v12.5.0-linux-x64.tar.xz
#Node HTTP Server
wget https://github.com/indexzero/http-server/archive/0.10.0.tar.gz


#Build DHCP Server
tar -zxvf dhcp-4.4.1.tar.gz && cd dhcp-4.4.1
CFLAGS="-static" ./configure
make
mkdir -p ${INSTALLDIR}/libexec/dhcpd
cp server/dhcpd ${INSTALLDIR}/libexec/dhcpd

cd ${INSTALLDIR}/build

#Build TFTP Server
tar -zxvf tftp-hpa-5.2.tar.gz
cd tftp-hpa-5.2
CFLAGS="-static" ./autogen.sh
CFLAGS="-static" ./configure
CFLAGS="-static" make
cd tftpd && gcc -static tftpd.o recvfrom.o misc.o remap.o ../common/libcommon.a ../lib/libxtra.a -lnsl -o tftpd
mkdir -p ${INSTALLDIR}/libexec/tftpd
cp tftpd ${INSTALLDIR}/libexec/tftpd/.

cd ${INSTALLDIR}/build


#Configure Node.js & install http server
tar -xvf node-v12.5.0-linux-x64.tar.xz
mkdir -p ${INSTALLDIR}/libexec/node-v12.5.0
cp -Rv node-v12.5.0-linux-x64/* ${INSTALLDIR}/libexec/node-v12.5.0
tar -zxvf 0.10.0.tar.gz
cd http-server-0.10.0
PATH=${INSTALLDIR}/libexec/node-v12.5.0/bin:$PATH npm i
cd ${INSTALLDIR}/build
cp -Rv http-server-0.10.0 ${INSTALLDIR}/libexec/.

cd ${INSTALLDIR}

#Create a dhcpd.conf file for the network in vars assuming
#that the tftp server is going to be defined in the vars file.

cat << EOF > etc/dhcpd.conf
# dhcpd.conf
#

allow booting;
allow bootp;
option option-128 code 128 = string;
option option-129 code 129 = text;
next-server $BUILDSERVER;
filename "pxelinux.0";


subnet $BUILDNETWORK netmask $BUILDNETMASK {
  range $DHCPSTART $DHCPEND;
}
EOF

#Place the syslinux files in the right location for the TFTP 
#server to dish out and in line with what we configured in 
#our dhcpd.conf.

cp /usr/share/syslinux/{vesamenu.c32,pxelinux.0} tftpboot/.

#Create the pxeboot.cfg/default file to instruct pxelinux what
#how to generate the pxe menu

mkdir -p tftpboot/pxelinux.cfg
cat << EOF > tftpboot/pxelinux.cfg/default
DEFAULT vesamenu.c32
PROMPT 0
MENU TITLE PXE Menu
TIMEOUT 100
TOTALTIMEOUT 1000
ONTIMEOUT 2

LABEL 1 local
  MENU LABEL ^1) Local
  MENU DEFAULT
  LOCALBOOT 0

EOF

cp $BASEPATH/../libexec/start.sh bin/.
cp $BASEPATH/../libexec/stop.sh bin/.
cat << EOF > etc/config
BASEDIR=${INSTALLDIR}
EOF

chmod +x bin/*