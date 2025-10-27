#!/usr/bin/env bash

# This script will deploy your NixOS configuration to a remote host.
# It will use the NixOS configuration from the flake in the current directory.
# It will also copy the age key to the remote host.
#
# Made by nuno.alves <at> rnl.tecnico.ulisboa.pt
# Adapted by me (luis <at> lhf.pt)

# Arguments:
# $1: The host to deploy. Example: your-host
# $2: The remote user. Example: root@your-ip

# Check if have 2 arguments
if [ ! $# -eq 2 ]; then
	echo "Usage: $0 <hostname> <remote user>"
	exit 1
fi

# Ensure that the options are correct
echo -e "Flake configuration: \e[1;35m.#$1\e[0m"
echo -e "Remote host: \e[1;31m$2\e[0m"

read -p "Are these options correct? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Aborting..."
	exit 1
fi

set -x

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
	rm -rf "$temp"
}
trap cleanup EXIT

install -d -m755 "$temp/nix/pst"
sops -d "secrets/deployer/$1.key" >"$temp/nix/pst/age.key"
chmod 600 "$temp/nix/pst/age.key"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake .#"$1" "$2"
