#!/bin/bash

# Initial OS update
echo '
#
# Step #0. Updating OS packages to prepare the system...
#
'
sleep 2
yum clean all && yum makecache
yum update -y --skip-broken
yum install -y epel-release
yum install -y nano htop bzip2
echo Done updating OS packages!
