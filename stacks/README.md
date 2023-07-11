# Stacks

This directory holds stacks that are ready for deployment to standard Docker hosts.

## Keepalived

[Keepalived](https://www.keepalived.org) is a service that enables any node in a cluster
to claim/respond to a virtual IP address. As such, it allows a cluster of servers, most
notably a Docker Swarm in this instance, to respond to a shared virtual IP address,
enabling the cluster to provide high availability fail-over response when a node in the
swarm cluster goes down!

## Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com) provides a reverse proxy to easily
expose Docker services at a particular address, with an easy-to-use UI.

## Portainer

[Portainer](https://www.portainer.io) is an easy-to-use administrative interface to your
Docker environment, making it easy to monitor and configure your Docker services.
