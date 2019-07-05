#!/bin/bash

# Script to download correct files and generate a sane pxelinux.cfg/default
# file to be able to quickly PXE boot and install CentOS7.

BUILDSERVERBASE='/opt/alces-bootserver'
HTTPBASE='/opt/alces-bootserver/resources'
ISOMIRROR='http://mirror.ox.ac.uk/sites/mirror.centos.org/7.6.1810/isos/x86_64/CentOS-7-x86_64-DVD-1810.iso'

if [ -e $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso ] ;
then
  echo "Media already downloaded, remove $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso if image not mounting"
fi


# ensure all children die when we do
trap "/bin/kill -- -$BASHPID &>/dev/null" EXIT INT TERM

function title() {
    printf "\n > $1\n"
}

function doing() {
    if [ -z "$2" ]; then
        pad=12
    else
        pad=$2
    fi
    printf "    %${pad}s ... " "$1"

}

function say_done () {
    if [ $1 -gt 0 ]; then
        echo 'FAIL'
        exit 1
    else
        echo 'OK '
    fi
}

download_media() {
doing "Downloading boot media from mirror"
wget --quiet -O $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso $ISOMIRROR
say_done $?
}

title "Preparing Media"
if [ ! -e $HTTPBASE/CentOS-7-x86_64-DVD-1810.iso ] ;
then
  download_media
fi

doing "Putting pxeboot files in place"
cp /usr/share/syslinux/{vesamenu.c32,pxelinux.0} ${BUILDSERVERBASE}/tftpboot/.
say_done $?


doing "Mounting boot media to be served by HTTP"
mkdir -p ${HTTPBASE}
mount -o loop,ro ${HTTPBASE}/CentOS-7-x86_64-DVD-1810.iso ${HTTPBASE}/centos7
say_done $?

doing "Putting kernel in place"
cp ${HTTPBASE}/centos7/images/pxeboot/vmlinuz ${BUILDSERVERBASE}/tftpboot/.
say_done $?

doing "Putting initrd in place"
cp ${HTTPBASE}/centos7/images/pxeboot/initrd.img ${BUILDSERVERBASE}/tftpboot/.
say_done $?

title "Generating configurations"

doing "pxeboot.cfg/default configuration"
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
  append initrd=centos_7.6.1810/images/pxeboot/initrd.img method=http://10.150.0.10/repo/centos/7.6.1810/base inst.vnc
EOF

say_done $?