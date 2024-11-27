# Stacks

This directory holds stacks that are ready for deployment to standard container hosts. The
installers will properly install to either Docker or Podman hosts. When installing to a
Podman host, a systemctl service will also be set up for the pod so that the containers
will start on boot.

## Inventory

### Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com) provides a reverse proxy to easily
expose Docker services at a particular address, with an easy-to-use UI.

### Portainer

[Portainer](https://www.portainer.io) is an easy-to-use administrative interface to your
Docker environment, making it easy to monitor and configure your Docker services.

## FAQs

### How do I install the stacks without running the whole setup?

You can run `./stacks/setup.sh` to just install the stacks, or run an individual stack's
install script directly, such as `./stacks/nginx-proxy-manager-install.sh`.

### How do I update the stacks with the latest version?

First, ensure your `docker-host` instance is using the latest code by navigating to its
directory and running `git pull`.

For minor version bumps, you can stop the stack and reinstall it with the installer script
and the `--upgrade` flag. This is not destructive; it will create containers using the
same data/volumes you had already set up.

#### Example: Stopping the stack

```bash
# On a Docker host, just use docker-compose:
docker-compose -f stacks/nginx-proxy-manager.yml down
# On a Podman host, you should use systemctl:
systemctl stop nginxproxymanager
```

#### Example: Reinstalling the stack with the `--upgrade` flag

```bash
./stacks/nginx-proxy-manager-install.sh --upgrade
```

This will automatically pull the latest version of the images while reinstalling.
