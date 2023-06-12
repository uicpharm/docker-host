# Experimental Features

This directory holds experimental features that are not fully developed or not desirable
for the standard Docker host configuration.

## Gluster

[Gluster](https://www.gluster.org) is a scalable network filesystem that keeps a local
copy of files synchronized between multiple peers. It can be used as a way to achieve a
shared persistent storage volume, but it is not performant with many small files. For
this reason, it may not be a good fit for our projects.
