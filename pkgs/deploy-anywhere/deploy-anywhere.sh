#!/usr/bin/env bash

# This script will deploy your NixOS configuration to a remote host.
# It will use the NixOS configuration from the flake in the current directory.
# It will also copy the ssh host key using agenix to the remote host.
#
# Made by nuno.alves <at> rnl.tecnico.ulisboa.pt
# Adapted by me (luis <at> lhf.pt)

# Arguments:
# $1: The host to deploy. Example: your-host
# $2: The remote user. Example: root@your-ip
# --agenix-args: Optional: arguments to pass to agenix. Example: --agenix-args="-d"
# --nixos-anywhere-args: Optional: arguments to pass to nixos-anywhere. Example: --nixos-anywhere-args="--extra-files /etc/nixos"

# Get extra agenix arguments
agenix_args=$(echo "$@" | sed -n 's/.*--agenix-args="\([^"]*\)".*/\1/p')

# Get extra nixos-anywhere arguments
nixos_anywhere_args=$(echo "$@" | sed -n 's/.*--nixos-anywhere-args="\([^"]*\)".*/\1/p')

# Check if have 2 arguments
if [ $# -lt 2 ]; then
	echo "Usage: $0 <hostname> <remote user> [--agenix-args=<args>] [--nixos-anywhere-args=<args>]"
	exit 1
fi

# Ensure that the options are correct
echo -e "Flake configuration: \e[1;35m.#$1\e[0m"
echo -e "Remote host: \e[1;31m$2\e[0m"
echo -e "Path to encrypted ssh host key: \e[1;33msecrets/host-keys/$1.age\e[0m"

if [ -n "$agenix_args" ]; then
	echo "Agenix arguments: $agenix_args"
fi
if [ -n "$nixos_anywhere_args" ]; then
	echo "NixOS Anywhere arguments: $nixos_anywhere_args"
fi

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

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Set the correct permissions so sshd will accept the key
touch "$temp/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Decrypt your private key from the password store and copy it to the temporary directory
pushd ./secrets || exit
HOST_KEY="host-keys/$1.age"
agenix -d "$HOST_KEY" ${agenix_args:+$agenix_args} >"$temp/etc/ssh/ssh_host_ed25519_key" || exit
popd || exit

# Set the user password
touch "$temp/etc/hashedPassword"
chmod 600 "$temp/etc/hashedPassword"
mkpasswd -m sha-512 >"$temp/etc/hashedPassword"

# If the root is a tmpfs, move the etc directory to the persistent storage
# if [ "$(nix eval ".#nixosConfigurations.$1.config.lhf.fsRoot.tmpfs")" = true ]; then
# 	install -d -m755 "$temp/pst/local"
# 	mv "$temp/etc" "$temp/pst/local/etc"
# fi

# Install NixOS to the host system with our secrets
nixos-anywhere "$nixos_anywhere_args" --extra-files "$temp" --flake .#"$1" "$2"
