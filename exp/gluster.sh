#!/bin/bash
echo '
#
# Draft: Installing Gluster...
#
'
sleep 2
yum install -y centos-release-gluster9 && \
yum install -y glusterfs glusterfs-libs glusterfs-server
systemctl start glusterd && systemctl enable glusterd

underline=$(tput smul)
norm=$(tput sgr0)

echo "
I only installed and started up gluster. You still need to:
- Set up peers with ${underline}gluster peer probe${norm}
- Create a gluster volume with ${underline}gluster volume create${norm}
- Start gluster volume with ${underline}gluster volume start${norm}
- You will probably want to set up the new volume in ${underline}/etc/fstab${norm}
"
