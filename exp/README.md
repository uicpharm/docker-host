# Experimental Features

This directory holds experimental features that are not fully developed or not desirable
for the standard Docker host configuration.

## Gluster

[Gluster](https://www.gluster.org) is a scalable network filesystem that keeps a local
copy of files synchronized between multiple peers. It can be used as a way to achieve a
shared persistent storage volume, but it is not performant with many small files. For
this reason, it may not be a good fit for our projects.

## Keepalived

[Keepalived](https://www.keepalived.org) is a service that enables any node in a cluster
to claim/respond to a virtual IP address. As such, it allows a cluster of servers,
perhaps a Docker Swarm, to respond to a shared virtual IP address, enabling the cluster
to provide high availability fail-over response when a node in the cluster goes down.
