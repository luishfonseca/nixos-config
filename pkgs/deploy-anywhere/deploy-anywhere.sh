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

# Get extra agenix arguments
agenix_args=$(echo "$@" | sed -n 's/.*--agenix-args="\([^"]*\)".*/\1/p')

# Check if have 2 arguments
if [ $# -lt 2 ]; then
	echo "Usage: $0 <hostname> <remote user> [--agenix-args=<args>]"
	exit 1
fi

# Ensure that the options are correct
echo -e "Flake configuration: \e[1;35m.#$1\e[0m"
echo -e "Remote host: \e[1;31m$2\e[0m"
echo -e "Path to encrypted ssh host key: \e[1;33msecrets/host-keys/$1.age\e[0m"

if [ -n "$agenix_args" ]; then
	echo "Agenix arguments: $agenix_args"
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
install -d -m755 "$temp/local/etc/ssh"

# Set the correct permissions so sshd will accept the key
touch "$temp/local/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$temp/local/etc/ssh/ssh_host_ed25519_key"

# Decrypt your private key from the password store and copy it to the temporary directory
pushd ./secrets || exit
HOST_KEY="host-keys/$1.age"
agenix -d "$HOST_KEY" ${agenix_args:+$agenix_args} >"$temp/local/etc/ssh/ssh_host_ed25519_key" || exit
popd || exit

# If config.lhf.zfs.fde.tpm.remote.enable is true, move the ssh key to /local/rd_shared and symlink it back
if [ "$(nix eval ".#nixosConfigurations.$1.config.lhf.zfs.fde.tpm.remote.enable")" = true ]; then
	install -d -m755 "$temp/local/rd_shared"
	mv "$temp/local/etc/ssh/ssh_host_ed25519_key" "$temp/local/rd_shared/ssh_host_ed25519_key"
	ln -sr "$temp/local/rd_shared/ssh_host_ed25519_key" "$temp/local/etc/ssh/ssh_host_ed25519_key"
fi

# Set the user password
touch "$temp/local/etc/hashedPassword"
chmod 600 "$temp/local/etc/hashedPassword"
mkpasswd -m sha-512 >"$temp/local/etc/hashedPassword"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake .#"$1" "$2"
