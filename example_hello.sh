#! /usr/bin/env bash
set -o nounset
set -o errexit
. getoptz.sh

# Variable 'file' will be set to the value of the first argument
add_arg name        --help "Your name."

# A flag (-v or --verbose)
add_opt verbose v   --help "Enable verbose mode."

getoptz_configure   --help "Print a hello world message."
getoptz_parse "$@"

# Your script begins here
[[ ! $verbose ]] || echo "[INFO] name=$name"
echo "Hello, $name!"
