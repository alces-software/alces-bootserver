#!/bin/bash

# Script to download correct files and generate a sane pxelinux.cfg/default
# file to be able to quickly PXE boot and install CentOS7.

BASEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
source $BASEPATH/../etc/vars

set -e
BUILDSERVERBASE=${INSTALLDIR}
LOGBASE="${INSTALLDIR}/var"
LOGFILE="${LOGBASE}/centos7_configure.log"
HTTPBASE="${BUILDSERVERBASE}/resources"
ISOMIRROR='http://mirror.ox.ac.uk/sites/mirror.centos.org/7.6.1810/isos/x86_64/CentOS-7-x86_64-DVD-1810.iso'

if [ -e $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso ] ;
then
  echo "Media already downloaded, remove $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso if image not mounting"
fi

trap 'echo Could not install CentOS7 to alces-bootserver, check logs.' ERR

download_media() {
echo "Downloading boot media from mirror"
curl -vs $ISOMIRROR -o $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso >> ${LOGFILE} 2>&1
}

echo "> Preparing Media"
if [ ! -e $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso ] ;
then
  download_media
fi

echo "    Putting pxeboot files in place"
cp /usr/share/syslinux/{vesamenu.c32,pxelinux.0} ${BUILDSERVERBASE}/tftpboot/. >> ${LOGFILE} 2>&1


echo "    Mounting boot media to be served by HTTP"
mkdir -p ${HTTPBASE}/centos7
mount -o loop,ro ${HTTPBASE}/CentOS-7-x86_64-DVD-1810.iso ${HTTPBASE}/centos7 >> ${LOGFILE} 2>&1

echo "    Putting kernel in place"
cp ${HTTPBASE}/centos7/images/pxeboot/vmlinuz ${BUILDSERVERBASE}/tftpboot/. >> ${LOGFILE} 2>&1

echo "    Putting initrd in place"
cp ${HTTPBASE}/centos7/images/pxeboot/initrd.img ${BUILDSERVERBASE}/tftpboot/. >> ${LOGFILE} 2>&1

echo "> Generating configurations"

echo "   pxeboot.cfg/default configuration"
cat << EOF > ${BUILDSERVERBASE}/tftpboot/pxelinux.cfg/default
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

label 2
  menu label ^2) Install CentOS 7 Manually
  kernel ./vmlinuz
  append initrd=initrd.img method=http://$BUILDSERVER/centos7
EOF

echo "Completed - logs at ${LOGFILE}"