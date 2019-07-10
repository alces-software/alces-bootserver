#!/bin/bash
BASEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
source $BASEPATH/../etc/config
INSTALLDIR=${BASEDIR}

for i in `ls ${INSTALLDIR}/var/*.pid`; do pkill --pidfile $i; done >> /opt/alces-bootserver/var/stop.log 2>&1

echo "Stopped all alces-bootserver processes that had written PIDs to file."