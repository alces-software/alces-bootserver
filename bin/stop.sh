#!/bin/bash

for i in `ls /opt/alces-bootserver/var/*.pid`; do pkill --pidfile $i; done >> /opt/alces-bootserver/var/stop.log 2>&1

