# Docker Host

Script and configuration for standing up a Docker host. This includes Docker, multiple
configured stacks, and a self-hosted GitHub Actions Runner.

## Installation

Right now, installation supports [CentOS](https://www.centos.org) 7 and
[Red Hat](https://www.redhat.com) 9 (which also works with RHEL lookalikes such as
[Rocky Linux](https://rockylinux.org)). Actual Docker installation is handled by
the installation script, but you can use the stacks installer on any *nix machine,
including macOS, by running [stacks/setup.sh](./stacks/setup.sh).

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

## FAQs

### How do I *[insert cool thing here]* with the stacks?

For more documentation about the stacks, please view the
[stacks readme](./stacks/README.md).

### How do I remove the GitHub Runner Service?

If you've installed the GitHub Runner service and now you want to remove it, you can do so
by following these steps:

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
