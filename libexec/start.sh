#!/bin/bash
BASEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
source $BASEPATH/../etc/config

set -e
trap 'echo Could not start alces-bootserver, check logs.' ERR

INSTALLDIR="${BASEDIR}"
LIBEXECDIR="${INSTALLDIR}/libexec"
ETCDIR="${INSTALLDIR}/etc"
LOGDIR="${INSTALLDIR}/var"
TFTPDIR="${INSTALLDIR}/tftpboot"
NODEDIR='node-v12.5.0'
HTTPSERVER='http-server-0.10.0'
HTTPSRVDIR="${INSTALLDIR}/resources"

#Start DHCP Server

touch ${LOGDIR}/dhcpd.leases

${LIBEXECDIR}/dhcpd/dhcpd -cf ${ETCDIR}/dhcpd.conf -pf ${LOGDIR}/dhcpd.pid -lf ${LOGDIR}/dhcpd.leases >> ${LOGDIR}/dhcpd_start.log 2>&1

#Start TFTP Server

${LIBEXECDIR}/tftpd/tftpd --listen -u root -spvvv ${TFTPDIR} -P ${LOGDIR}/tftpd.pid 2>&1 >> ${LOGDIR}/tftp_server.log &

#Start HTTP Server

${LIBEXECDIR}/${NODEDIR}/bin/node ${LIBEXECDIR}/${HTTPSERVER}/bin/http-server -p 80 ${HTTPSRVDIR} >> ${LOGDIR}/http_server.log 2>&1 & echo $! > ${LOGDIR}/http.pid &

echo "Successfully started alces-bootserver."