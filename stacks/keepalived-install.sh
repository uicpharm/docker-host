#!/bin/bash
echo '
#
# Installing Keepalived as a stack...
#
'
sleep 2
scr_dir="${0%/*}"
echo -n 'Enter the high availability virtual IP(s): [hit enter to skip] '
read -r vips
if [ -n "$vips" ]; then
   echo Adding virtual IP configuration...
   echo "KEEPALIVED_VIRTUAL_IPS=$vips" > "$scr_dir"/keepalived.env
   echo Assigning keepalived priorities to each node randomly...
   for id in $(docker node ls -q); do
      docker node update "$id" --label-add KEEPALIVED_PRIORITY=$(( ( RANDOM % 1000 ) + 1 ))
   done
   docker stack deploy -c "$scr_dir"/keepalived.yml keepalived
else
   echo Skipped installation of keepalived.
fi