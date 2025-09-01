#!/bin/bash

version=1.0.0
bold=$(tput bold)
ul=$(tput smul)
rmul=$(tput rmul)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
norm=$(tput sgr0)

arches_default=linux/aarch64,linux/x86_64
org_default=uicpharm
reg_default=ghcr.io

arches=$arches_default
org=$org_default
reg=$reg_default
name_append=
dry_run=false
exact=false
push=true
verbose=false

err() { echo "$red$1$norm" >&2; }
warn() { echo "$yellow$1$norm" >&2; }
exec_cmd() { if $dry_run; then echo "${yellow}Command:${norm} $1" | tr -s ' '; else eval "$1"; fi }

display_version() {
   hash=$(cat "$0" | sha256sum | cut -c1-8)
   echo "$(basename "$0") version $version build $hash"
}

display_help() {
   cat <<EOF
$bold$(display_version)$norm
${red}UIC Retzky College of Pharmacy$norm

Usage: $(basename "$0") <Dockerfile> [context] [OPTIONS]

Builds and publishes a container image with UIC Pharmacy standards:
   - Semantic versioning based on ${ul}version$norm in package.json
   - Automatically assign to a repo based on ${ul}homepage$norm in package.json
   - Create a multi-arch manifest
   - Assumes context same directory as Dockerfile. You can specify if needed.

This supports multiple images for a single repo. You can use $bold--name$norm to specify
the additional name. So, if your repo name is ${bold}foo$norm and $bold--name=bar$norm, then the full
name would be ${bold}foo/bar$norm.

Options:
-h, --help        Show this help message and exit.
-a, --arch        Architectures to build for. (Default: $ul$arches_default$rmul)
-e, --exact       Only tag the exact version from the package file.
-n, --name        Additional name to append to the image name.
-o, --org         Organization to push to. (Default: $ul$org_default$rmul)
-r, --registry    Registry to push to. (Default: $ul$reg_default$rmul)
    --dry-run     Show what would've happened without executing.
    --no-push     Create the images, but do not push to registry.
-v, --verbose     Provide more verbose output.
-V, --version     Print version and exit.
EOF
}

# Positional parameter: Docker file
if ! [[ $1 == -* || -z $1 ]]; then
   dockerfile=$(realpath "$1")
   shift
fi

# Positional parameter: Context
if [[ $1 == -* || -z $1 ]]; then
   # If not provided, we assume same dir as Docker file
   context=$(dirname "$dockerfile")
else
   context=$(realpath "$1")
   shift
fi

# Collect optional arguments.
# spellchecker: disable-next-line
while getopts hevVa:n:o:r:-: OPT; do
   # Ref: https://stackoverflow.com/a/28466267/519360
   if [ "$OPT" = "-" ]; then
      OPT="${OPTARG%%=*}"       # extract long option name
      OPTARG="${OPTARG#"$OPT"}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
   fi
   case "$OPT" in
      h | help) display_help; exit 0 ;;
      V | version) display_version; exit 0 ;;
      a | arch) arches=$OPTARG ;;
      e | exact) exact=true ;;
      dry-run) dry_run=true ;;
      no-push) push=false ;;
      n | name) name_append=${OPTARG// /} ;;
      o | org) org=$OPTARG ;;
      r | registry) reg=$OPTARG ;;
      v | verbose) verbose=true ;;
      \?) err "Invalid option: -$OPT" ;;
      *) err "Some of these options are invalid: $*"; exit 2 ;;
   esac
done
shift $((OPTIND - 1))

# Check Docker file
[[ -z $dockerfile ]] && err "You must provide a Docker file." && exit 2

# Check if podman or docker is present
if [[ $(docker --version 2> /dev/null) =~ Docker ]]; then
   container_binary=docker
   is_podman=false
elif [[ $(podman --version 2> /dev/null) =~ podman ]]; then
   container_binary=podman
   is_podman=true
else
   err 'This script requires either Docker or Podman. Aborting.'
   ext 1
fi

# Check dependencies, and abort if any are missing
for c in tput realpath dirname basename "$container_binary" jq; do
   if ! which "$c" &>/dev/null; then
      err "The $ul$c$rmul command is required by this script. Aborting."
      exit 1
   fi
done

# Check arch... when running as podman, only support native arch.
# Get arch info from docker/podman itself. Sadly, they report that info differently.
docker_info=$("$container_binary" info -f json)
native_arch=$(jq -r '.OSType' <<< "$docker_info")/$(jq -r '.Architecture' <<< "$docker_info")
$is_podman && native_arch=$(jq -r '.host.os' <<< "$docker_info")/$(jq -r '.host.arch' <<< "$docker_info")
if $is_podman && [[ $arches != "$native_arch" ]]; then
   arches=$native_arch
   warn "When running podman, you can only run your native architecture. Changing target arch to $ul$arches$rmul."
fi

# Repo package info
name=$(jq -r '.name' "$context/package.json" | tr -d ' ')
ver=$(jq -r '.version' "$context/package.json" | tr -d ' ')
homepage=$(jq -r '.homepage' "$context/package.json" | tr -d ' ')

# Validation of name/version as required values
[[ $name == null ]] && name=
[[ -z $name ]] && err "No ${ul}name$rmul provided in package.json." && exit 1
[[ $ver == null ]] && ver=
[[ -z $ver ]] && err "No ${ul}version$rmul provided in package.json." && exit 1
img=$reg/$org/$name${name_append:+/$name_append}

# We want homepage without any anchor or query params
homepage=${homepage%#*}
homepage=${homepage%\?*}
# Warn if homepage is not provided
[[ $homepage == null ]] && homepage=
[[ -z $homepage ]] && warn "No ${ul}homepage$rmul provided in package.json. The image will be pushed, but will not be assigned to a repository."

# Make sure container builder exists (not needed for podman)
if ! $is_podman; then
   builder="$org-builder"
   builder_param="--builder $builder"
   if ! docker builder inspect "$builder" &>/dev/null; then
      $verbose && echo -n 'Creating custom builder: '
      exec_cmd "docker builder create --name $builder"
   fi
fi

# Parse the version into major, minor, and patch components
maj=$(echo "$ver" | awk -F. '{print $1}')
min=$(echo "$ver" | awk -F. '{print $2}')
pat=$(echo "$ver" | awk -F. '{print $3}')

# Generate different tags
tag_maj=$img:$maj
tag_min=$img:$maj.$min
tag_pat=$img:$maj.$min.$pat
tag_full=$img:$ver
latest=$img:latest

# Use all variations for normal versions, but not for prereleases
if ! $exact && [[ $tag_full == "$tag_pat" ]]; then
   tags=("$tag_maj" "$tag_min" "$tag_pat" "$latest")
else
   tags=("$tag_full")
fi

# Output the variables for verification
if $verbose; then
   echo
   echo "${bold}${ul}Building $img$norm"
   echo
   echo "${bold}Container Tool:$norm $container_binary"
   [[ -n $builder ]] && echo "${bold}Builder:$norm $builder"
   echo "${bold}Dockerfile:$norm $dockerfile"
   echo "${bold}Context:$norm $context"
   [[ -n $homepage ]] && echo "${bold}Parent project:$norm $homepage"
   echo "${bold}Package version:$norm $ver"
   echo  "${bold}Tags:$norm"
   for tag in "${tags[@]}"; do echo "  - $tag"; done
   echo "${bold}Platforms:$norm"
   for a in ${arches//,/ }; do echo "  - $a"; done
   echo
fi

#
# Docker builds the image and only keeps it in the builder cache unless you push it.
# Podman tags the images in your local images, but doesn't support a `--push` flag. So,
# if the user is pushing the images, we use `--push` for Docker, but for podman we use
# additional `docker push <tag>` calls.
#

# Build images and push them to the registry
$push && ! $is_podman && push_param=--push
exec_cmd "$container_binary build \
   -f $dockerfile \
   --platform $arches \
   $(for tag in "${tags[@]}"; do echo -n "-t $tag "; done) \
   ${homepage:+--annotation "org.opencontainers.image.source=$homepage"} \
   $builder_param \
   $push_param \
   $context"

# In podman, we have to push the tags after building
$is_podman && $push && for tag in "${tags[@]}"; do
   exec_cmd "podman push $tag"
done

# Stop builder when done (not needed for podman)
$is_podman || exec_cmd "docker builder stop $builder"
