# Docker Host

Script and configuration for standing up a Docker host. This includes Docker, Portainer, Nginx Proxy Manager,
and a self-hosted GitHub Actions Runner.

This is a work in progress.

## Installation on CentOS

To run on a CentOS 7 installation, login as root and execute:

```sh
source <(curl -H 'Cache-Control: no-cache, no-store' -o- https://raw.githubusercontent.com/uicpharm/docker-host/main/centos-7/setup.sh)
```

## Removing the GitHub Runner Service

As `root`:

```sh
cd /home/github/actions-runner
./svc.sh stop
./svc.sh uninstall
```

Then, as the `github` user:

```sh
cd actions-runner
./config.sh remove --token your-token-supplied-by-github
```
