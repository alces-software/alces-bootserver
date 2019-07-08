#!/bin/bash

set -e

LIBEXECDIR='/opt/alces-bootserver/libexec'
ETCDIR='/opt/alces-bootserver/etc'
LOGDIR='/opt/alces-bootserver/var'
TFTPDIR='/opt/alces-bootserver/tftpboot'
NODEDIR='node-v12.5.0'
HTTPSERVER='http-server-0.10.0'
HTTPSRVDIR='/opt/alces-bootserver/resources'

#Start DHCP Server

touch ${LOGDIR}/dhcpd.leases

${LIBEXECDIR}/dhcpd/dhcpd -cf ${ETCDIR}/dhcpd.conf -pf ${LOGDIR}/dhcpd.pid -lf ${LOGDIR}/dhcpd.leases >> ${LOGDIR}/dhcpd_start.log 2>&1

#Start TFTP Server

${LIBEXECDIR}/tftpd/tftpd --listen -u root -spvvv ${TFTPDIR} -P ${LOGDIR}/tftpd.pid 2>&1 >> ${LOGDIR}/tftp_server.log &

#Start HTTP Server

${LIBEXECDIR}/${NODEDIR}/bin/node ${LIBEXECDIR}/${HTTPSERVER}/bin/http-server -p 80 ${HTTPSRVDIR} >> ${LOGDIR}/http_server.log 2>&1 & echo $! > ${LOGDIR}/http.pid &

echo "Successfully started alces-bootserver."