# Docker Host

Script and configuration for standing up a Docker host. This includes Docker, multiple
configured stacks, and a self-hosted GitHub Actions Runner.

## Before you start

If you are indeed setting up a cluster, the data directory where everything goes should
be a **SHARED PERSISTENT STORAGE** volume, whether that be via NFS or any other means
that your virtualization environment supports. You're expected to have this already set
up before you begin.

## Installation

Right now, installation only supports CentOS 7. Actual Docker installation is handled by
the installation script, but you can use the stacks installer on any *nix machine,
including macOS, using [stacks/setup.sh](./stacks/setup.sh).

Login as root and execute:

```sh
source <(curl -H 'Cache-Control: no-cache, no-store' -o- https://raw.githubusercontent.com/uicpharm/docker-host/main/init.sh)
```

The script will download the project and walk you through executing the scripts.

If you cannot login as root and can only sudo, then download it to your home directory and
execute it from there:

```sh
curl -H 'Cache-Control: no-cache, no-store' -o- https://raw.githubusercontent.com/uicpharm/docker-host/main/init.sh > init.sh && \
chmod +x init.sh && \
sudo ./init.sh
```

## A note about Swarm

The Docker installation sets up a swarm. On the first server, you should choose to
initialize the swarm. Then the following servers should join the swarm.

You can wait until you run installation on the last server in your cluster before you
install the stacks, although there's no harm done in "reinstalling" the stacks.

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
