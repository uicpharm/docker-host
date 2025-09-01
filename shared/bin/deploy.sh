#!/bin/bash

version=1.0.0
bold=$(tput bold)
dim=$(tput dim)
ul=$(tput smul)
rmul=$(tput rmul)
red=$(tput setaf 1)
norm=$(tput sgr0)

repo_default=ghcr.io/uicpharm
repo=$repo_default
upgrade=false
verbose=false
interactive=true
env_file=

display_version() {
   hash=$(cat "$0" | sha256sum | cut -c1-8)
   echo "$(basename "$0") version $version build $hash"
}

display_help() {
   cat <<EOF
$bold$(display_version)$norm
${red}UIC Retzky College of Pharmacy$norm

Usage: $(basename "$0") <stack path> [OPTIONS]

Deploys an application stack with UIC Pharmacy standards:
   - Login to your Docker repo
   - Stop the application if it is currently running
   - Create a pod $dim(if using podman)$norm
   - Start up the stack using the stack path you point at
   - Install the stack as a service $dim(if using podman)$norm

Options:
-h, --help              Show this help message and exit.
-e, --env-file          Specify an alternate environment file.
-n, --non-interactive   Do not prompt, run in non-interactive mode.
-r, --repo              Specify the repo to login to. (Default: $ul$repo_default$rmul)
-u, --upgrade           Upgrade by pulling the latest image.
-v, --verbose           Provide more verbose output.
-V, --version           Print version and exit.
EOF
}

# Positional parameter: Stack Path
if ! [[ $1 == -* || -z $1 ]]; then
   stack_path=$(realpath "$1")
   shift
fi

# Collect optional arguments.
# spellchecker: disable-next-line
while getopts hnuvVe:r:-: OPT; do
   # Ref: https://stackoverflow.com/a/28466267/519360
   if [ "$OPT" = "-" ]; then
      OPT="${OPTARG%%=*}"       # extract long option name
      OPTARG="${OPTARG#"$OPT"}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
   fi
   case "$OPT" in
      h | help) display_help; exit 0 ;;
      V | version) display_version; exit 0 ;;
      r | repo) repo=$OPTARG ;;
      e | env-file) env_file=$(realpath "$OPTARG") ;;
      n | non-interactive) interactive=false ;;
      u | upgrade) upgrade=true ;;
      v | verbose) verbose=true ;;
      \?) echo "${red}Invalid option: -$OPT$norm" >&2 ;;
      *) echo "${red}Some of these options are invalid:$norm $*" >&2; exit 2 ;;
   esac
done
shift $((OPTIND - 1))

# Validation
[[ -z $stack_path ]] && echo "${red}You must provide a stack path.$norm" >&2 && exit 1
[[ ! -e $stack_path ]] && echo "${red}The stack $ul$stack_path$rmul doesn't exist.$norm" >&2 && exit 2

dir=${stack_path%/*}
env_file=${env_file:-$dir/.env} # If no env file provided, use standard `.env` in stack directory
pod_name=$(basename "$dir")-$(basename "$stack_path" .yml)

$verbose && (
   echo "$bold${ul}Settings$norm"
   echo
   echo "${bold}Stack Path:$norm $stack_path"
   echo "${bold}Env File:$norm $env_file"
   echo "${bold}Pod Name:$norm $pod_name"
   echo "${bold}Repo:$norm $repo"
   echo "${bold}Upgrade:$norm $upgrade"
   echo
)

# Check if logged into ghcr.io/uicpharm
$interactive && (
   echo "Checking login to $repo..."
   if ! docker login "$repo"; then
      echo "Access to $repo is required. Aborting."
      exit 1
   fi
)

# Detect podman
[[ $(docker --version) == podman* ]] && IS_PODMAN=true || IS_PODMAN=false

# Detect podman-install-service
which podman-install-service &> /dev/null && HAS_SERVICE_INSTALLER=true || HAS_SERVICE_INSTALLER=false

# Function that will use `podman-compose` or `docker compose` depending on presence of podman
compose() {
   if $IS_PODMAN; then
      podman-compose "$@"
   else
      docker compose "$@"
   fi
}

# Stop the stack. Detect if its a service with systemctl or just a compose stack.
# By querying `is-active`, and then checking `compose ps`, it will even catch the
# scenario when the service is newly created but systemctl doesn't see it yet.
if which systemctl &> /dev/null && ! systemctl status "$pod_name" 2>&1 | grep -q 'could not be found' && systemctl -q is-active "$pod_name"; then
   systemctl stop "$pod_name"
elif [[ $(compose -f "$stack_path" --env-file "$env_file" ps -q 2>/dev/null | wc -w) -gt 0 ]]; then
   compose -f "$stack_path" down
fi

# Create pod
$IS_PODMAN && ! podman pod exists "$pod_name" && podman pod create --name "$pod_name"

# Prep compose args
podman_args=()
docker_args=('-d')
$IS_PODMAN && podman_args+=(--in-pod "$pod_name")

# Upgrade stack if requested
if $upgrade; then
   $IS_PODMAN && podman_args+=(--podman-run-args '--pull always') || docker_args+=(--pull always)
fi

# Start stack and install service
(
   cd "$dir" && \
   compose "${podman_args[@]}" -f "$stack_path" --env-file "$env_file" up "${docker_args[@]}" && \
   $IS_PODMAN && $HAS_SERVICE_INSTALLER && podman-install-service "$pod_name" -n && \
   echo "Installed service $pod_name!"
)
