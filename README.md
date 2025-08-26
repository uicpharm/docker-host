# Docker Host

Script and configuration for standing up a Docker host. This includes Docker, multiple
configured stacks, and a self-hosted GitHub Actions Runner.

## Installation

Right now, installation supports [Red Hat](https://www.redhat.com) 9 (which also works
with RHEL lookalikes such as [Rocky Linux](https://rockylinux.org)),
[macOS](https://www.apple.com/os/macos), and [Ubuntu](https://ubuntu.com). WSL should be
support by virtue of support for Ubuntu. Actual Docker installation is handled by the
installation script, but you can use the stacks installer directly on any *nix machine by
running [stacks/setup.sh](./stacks/setup.sh).

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

### Using the `deploy` script

For all environments, a `deploy` script is installed in the system that helps with
deploying applications that use the docker-host environment. They provide a compose stack
and any additional required files (`.env` file, etc), and then deploy with this script.

It takes these standard steps for deployment of UIC Pharmacy stacks:

   - Login to your Docker repo
   - Stop the application if it is currently running
   - Create a pod *(if using podman)*
   - Start up the stack using the stack path you provide
   - Install the stack as a service *(if using podman)*

Example:

```bash
deploy production.yml
```

This will automatically deploy the application and install it as a service named
`prior-auth-drug-search-production`, if you are running a `podman` system.

Note if you are using an environment file named something other than `.env`, you must
pass it to the script as well:

```bash
deploy production.yml --env-file=production.env
```

The deploy script can handle upgrades as well. Just pass the `--upgrade` flag to ensure
it handles pulling fresh container images:

```bash
deploy production.yml --upgrade
```

### Using the `publish` script

For all environments, the `publish` script helps with building and publishing container
images from your workstation to our container registry. It builds the image using the UIC
Pharmacy standards, such as:

   - Uses semantic versioning based on the `version` defined in `package.json`, including
     intelligent re-tagging of major versions. For instance, version `1.2.3` will also
     tag versions `1` and `1.2`, however a prerelease like `1.2.3-beta.1` will not.
   - Automatically adds the image to the correct repo as long as its `homepage` is set in
     `package.json`.
   - Creates a multi-arch manifest, so images are built for Intel and Apple Silicon
     architectures.
   - Automatically finds the context and `package.json` by assuming they're in the same
     directory as the Dockerfile.

Since podman and buildah do not support non-native architecture builds (i.e. building for
arm64 in an amd64 environment), this script will force building only for your native
architecture when it runs in a podman environment.

You can build and publish the image for a project with a single Dockerfile by just
referencing the Dockerfile in the command:

```bash
# For project 'foo', creates image 'ghcr.io/uicpharm/foo':
publish path/to/Dockerfile
```

If you have a project with multiple Docker files, build them one at a time, assigning an
additional name that can be appended to the image.

```bash
# For project 'foo', creates image 'ghcr.io/uicpharm/foo/bar':
publish path/to/Dockerfile.bar --name=bar
```

If you want to make sure it's working without actually publishing, here are some things
you could do to check it:

`--dry-run` will show you the commands that will run, without actually running them.

`--no-push` will build the images but not push them to the registry.

`--verbose` will show you a summary of all the settings that will be used for the build
and publishing process.

### How do I remove the GitHub Runner Service?

If you've installed the GitHub Runner service and now you want to remove it, you can do so
by following these steps:

As `root`:

```sh
cd /home/github/runner
./svc.sh stop
./svc.sh uninstall
```

Then, as the `github` user:

```sh
cd ~/runner
./config.sh remove --token your-token-supplied-by-github
```
