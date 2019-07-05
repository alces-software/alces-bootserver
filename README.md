# alces-bootserver
Tools for building and running pxeboot server
#### Configuration

```
# git clone https://github.com/alces-software/alces-bootserver.git
# cd  alces-bootserver
```
You will then need to modify the `etc/vars` file which provides the configuration for a DHCP server for the network of the build interface.
```
# vim etc/vars
# ./bin/build.sh
```
To automatically provide CentOS 7 Installation media, run the script in your git clone directory `~/alces-bootserver/bin/configure_centos7_install.sh` which will provide all the required files to perform basic installations of CentOS 7 using the upstream provided ISO media.

Alternatively place any required files requiring to be served by TFTP at `/opt/alces-bootserver/tftpboot` and any files in `/opt/alces-bootserver/resources` to be made available via HTTP.

#### Starting

Once you have the files required for PXE Booting in place:

```
[root@localhost alces-bootserver]# cd /opt/alces-bootserver
[root@localhost alces-bootserver]# ./bin/start.sh
Successfully started alces-bootserver.
```
Your PXE boot server should be running, logs are located at `/opt/alces-bootserver/var/`.

#### Stopping alces-bootserver
Execute script:
```
[root@localhost alces-bootserver]# cd /opt/alces-bootserver
[root@localhost alces-bootserver]# ./bin/stop.sh
```


