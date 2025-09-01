#!/bin/bash

version=1.0.0
bold=$(tput bold)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
ul=$(tput smul)
rmul=$(tput rmul)
norm=$(tput sgr0)
branch=main
dev=false
help_only=false
version_only=false
stacks_only=false
runner_only=false

# Asks a yes/no question and returns 0 for 'yes' and 1 for 'no'. If the user does not
# provide a response, it uses the default value.
function yorn() {
   local question=$1
   local default=${2:-y}
   while true; do
      echo -n "$question " >&2
      [[ $default =~ [Yy] ]] && echo -n "[Y/n]: " >&2 || echo -n "[y/N]: " >&2
      read -r response
      [[ -z $response ]] && response=$default
      response=$(echo "${response:0:1}" | tr '[:upper:]' '[:lower:]')
      if [[ $response == y ]]; then
         return 0
      elif [[ $response == n ]]; then
         return 1
      else
         echo "Please answer 'y' or 'n'." >&2
      fi
   done
}

function display_version() {
   echo -n "Docker Host version $version build "
   find "$dir" -type f \( -name '*.sh' -o -name '*.yml' \) -not -path '*/node_modules/*' | \
   sort | xargs cat | sha256sum | cut -c1-8
}

# Title for the script
function display_title() {
   local -r ver=$(display_version)
   echo "$bold"
   echo "   ___             __               __ __           __ "
   echo "  / _ \ ___  ____ / /__ ___  ____  / // /___   ___ / /_"
   echo " / // // _ \/ __//  '_// -_)/ __/ / _  // _ \ (_-</ __/"
   echo "/____/ \___/\__//_/\_\ \__//_/   /_//_/ \___//___/\__/ "
   echo
   echo "Containerization on UIC Pharmacy servers $yellow(${ver/Docker Host version /v})"
   echo "$norm"
}

# Help
function display_help() {
   display_title
   cat <<EOF
Usage: $0 [OPTIONS]

Sets up an OS for container tooling and installs additional useful scripts for
container management according to UIC Pharmacy standards:

   - ${bold}deploy$norm: Helps deploy a stack.
   - ${bold}publish$norm: Takes a Dockerfile and publishes multi-arch images.
   - ${bold}podman-install-service$norm: Installs a Podman pod as a service.

Options:
-h, --help         Show this help message and exit.
-d, --dev          Install in developer mode, just create a symlink.
-b, --branch       Branch to use for installation files.
    --stacks-only  Only run the stack installation.
    --runner-only  Only run the GitHub Actions runner installation.
-V, --version      Print version and exit.
EOF
}

# Collect optional arguments.
# spellchecker: disable-next-line
while getopts hb:dV-: OPT; do
   # Ref: https://stackoverflow.com/a/28466267/519360
   if [ "$OPT" = "-" ]; then
      OPT="${OPTARG%%=*}"       # extract long option name
      OPTARG="${OPTARG#"$OPT"}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
   fi
   case "$OPT" in
      h | help) help_only=true ;;
      b | branch) branch=$OPTARG ;;
      d | dev) dev=true ;;
      stacks-only) stacks_only=true ;;
      runner-only) runner_only=true ;;
      V | version) version_only=true ;;
      \?) echo "${red}Invalid option: -$OPT$norm" >&2 ;;
      *) echo "${red}Some of these options are invalid:$norm $*" >&2; exit 2 ;;
   esac
done
shift $((OPTIND - 1))

# Prerequisite commands
for cmd in curl cut find gzip install mktemp sort tar tr; do
   if ! which "$cmd" > /dev/null; then
      echo "${bold}${red}This installer requires $ul$cmd$rmul to work.$norm" >&2
      exit 1
   fi
done

# Load installer files into a temp directory
export dev
if $dev; then
   dir=$(dirname "$(realpath "$0")")
   echo "Will install from $dir in dev mode..."
else
   echo "Downloading installation files from $branch branch..."
   dir=$(mktemp -d -t uicpharm-docker-host-XXXXXX)
   url=https://github.com/uicpharm/docker-host/archive/refs/heads/$branch.tar.gz
   curl -fsL "$url" | tar xz --strip-components=1 -C "$dir"
fi

# Help/version options only display their info and exit
if $help_only; then
   display_help
   exit
elif $version_only; then
   display_version
   exit
fi

display_title
# Warn that we will ask for sudo password.
if [[ $EUID -ne 0 ]]; then
   echo "Part of the installation requires 'sudo'. You may be asked for a sudo password."
   echo
fi

# Calculate the default flavor based on what we see on the system
default_flavor=''
if [[ "$(uname)" == "Darwin" ]]; then
   default_flavor="macos"
elif [[ -f /etc/os-release ]]; then
   # shellcheck source=/dev/null
   . /etc/os-release
   id_lowercase=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
   major_version=${VERSION_ID%%.*}
   default_flavor=${id_lowercase}-${major_version}
fi

# Available flavor installers
flavors=$(find "$dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) ! -name 'exp' ! -name 'node_modules' ! -name 's*' ! -name '.*' | awk -F'/' '{print $NF}' | sort)
[[ ! $flavors =~ $default_flavor ]] && default_flavor=''

if [[ -n $default_flavor ]] && yorn "It looks like you're running on $ul$default_flavor$norm, is that right?" y; then
   flavor=$default_flavor
else
   PS3="Select your Linux flavor: "
   select flavor in $flavors; do
      [[ -z $flavor ]] && echo "Invalid selection, try again!" >&2 && continue
      break
   done
fi

if [[ ! $flavors =~ $flavor ]]; then
   echo "Aborting because $ul$flavor$norm is not a valid choice."
   exit 1
fi

# All flavors should run as sudo, except macOS.
cmd=(env) && [[ $flavor != macos ]] && cmd=(sudo env)
cmd+=(DEV="$dev")
if $stacks_only; then
   cd "$dir/shared" || exit 1
   cmd+=(./stacks.sh)
elif $runner_only; then
   cd "$dir/shared" || exit 1
   cmd+=(./github-actions-runner.sh)
else
   cd "$dir/$flavor" || exit 1
   cmd+=(./setup.sh)
fi
"${cmd[@]}"
