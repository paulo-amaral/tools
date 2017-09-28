#!/bin/sh
# Script to check if NFS is mounted properly
#change /opt/backup to reflect your nfs mountpoint

REMOTESERVER_IP='' 
REMOTEFOLDER=''
MOUNTPOINT=''
#check if nfs is mounted
nfs_mounted=$(cat /etc/mtab | grep /opt/backup)
if [ -z "${nfs_mounted}" ]; then
    echo "not mounted!!"
     mount $REMOTESERVER_IP:$REMOTEFOLDER $MOUNTPOINT
else
    echo "nfs mounted!"
fi
