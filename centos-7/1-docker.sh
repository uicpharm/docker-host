#!/bin/bash

# Setup Docker
echo '
#
# Step #1. Installing Docker...
#
'
sleep 2

# Collect IP addresses *before* installing Docker, as an easy way to not include the virtual docker IP addresses.
# Manipulate the list: Only use IPv4. Exclude localhost. Only include the IP address and no subnet.
ip_addresses=$(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1)

# Standard Install
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Open up firewall for swarm
if [ -n "$(command -v ufw)" ]; then
   echo Opening up ports with ufw...
   ufw allow 2376/tcp
   ufw allow 2377/tcp
   ufw allow 7946/tcp
   ufw allow 7946/udp
   ufw allow 4789/udp
   ufw reload
elif [ -n "$(command -v firewall-cmd)" ]; then
   echo Opening up ports with firewall-cmd...
   firewall-cmd --add-port=2376/tcp --permanent
   firewall-cmd --add-port=2377/tcp --permanent
   firewall-cmd --add-port=7946/tcp --permanent
   firewall-cmd --add-port=7946/udp --permanent
   firewall-cmd --add-port=4789/udp --permanent
   firewall-cmd --reload
fi

# Start/Enable Docker
systemctl start docker
systemctl enable docker

# Create a `docker` user. A `docker` group is created during installation.
useradd -M -g docker -u 1001 docker

# Either init or join a swarm
PROCEED=false
while ! $PROCEED; do
   PS3="What cluster action will this server perform? "
   select action in "Initialize a Swarm" "Join a Swarm" "Do not set up Swarm"; do
      if [ -z "$action" ]; then echo "'$REPLY' is not a choice."; else break; fi
   done
   if [ "$REPLY" = "1" ]; then
      if [ "$(echo "$ip_addresses" | wc -l)" -eq 1 ]; then
         # If there is only one IP address, use it.
         echo "Will use the IP address $ip_addresses."
         advert_ip_address="$ip_addresses"
      else
         # Otherwise, ask the user which IP address to use.
         PS3='Which IP address should the Swarm advertise? '
         select ip in $ip_addresses; do
            if [ -n "$ip" ]; then
               advert_ip_address="$ip"
               break
            else
               echo 'You must choose one of these IP addresses.'
            fi
         done
      fi
      docker swarm init --advertise-addr "$advert_ip_address" && \
      docker swarm join-token manager && \
      echo IMPORTANT: Copy the command above. You will paste it to the other nodes. && \
      echo -n "Hit enter when ready to proceed. " && \
      PROCEED=true && \
      read -r
   elif [ "$REPLY" = "2" ]; then
      echo -n "Please paste the join command provided by the first node: "
      read -r cmd
      eval "$cmd" && \
      PROCEED=true
   else
      echo 'Skipping Swarm configuration.'
      PROCEED=true
   fi
done

echo "Please provide credentials to $(tput smul)ghcr.io/uicpharm$(tput sgr0) for future projects to download images."
PROCEED=false
while ! $PROCEED; do
   if docker login ghcr.io/uicpharm; then
      PROCEED=true
   else
      echo -n 'Did you want to try again? [Y/n]: '
      read -r yorn
      [[ "${yorn:-Y}" =~ [Nn] ]] && PROCEED=true && echo Skipping Docker authentication.
   fi
done

echo Done installing Docker!
