#!/bin/bash

SCRIPT_TITLE="Updating OS packages and prepare the system"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

dnf clean all && dnf makecache
dnf update -y --skip-broken
[ -n "$(command -v subscription-manager)" ] && subscription-manager repos --enable "codeready-builder-for-rhel-9-$(arch)-rpms"
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y nano htop bat bzip2 rsync
echo Done updating OS packages!
