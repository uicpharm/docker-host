#!/bin/bash

SCRIPT_TITLE="Updating OS packages and prepare the system"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

yum clean all
! yum makecache && \
   echo Unable to update the yum package repository. You must resolve this to continue. >&2 && \
   exit 1
yum update -y --skip-broken
yum install -y epel-release
yum install -y nano htop bzip2 rsync
echo Done updating OS packages!
