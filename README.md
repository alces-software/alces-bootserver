# alces-bootserver
Tools for building and running pxeboot server
#### Usage

```
# git clone https://github.com/alces-software/alces-bootserver.git
# cd  alces-bootserver
```
You will then need to modify the `etc/vars` file and build the files required.
```
# vim etc/vars
# ./bin/build.sh
wait...
./bin/start.sh
```

Your PXE boot server should be running, just place the kernel images in `/opt/alces-bootserver/tftpboot` and the root filesystems in `/opt/alces-bootserver/resources` to be made available via HTTP.
