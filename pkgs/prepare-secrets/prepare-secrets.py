#!/usr/bin/env python3

import sys
import subprocess
import tempfile
from difflib import unified_diff
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import PlainScalarString

def add_key(data, host, key):
	for existing_key in data["keys"]:
		if existing_key.anchor.value == host:
			print(f"\nKey for host {host} already exists. Aborting.")
			exit(1)

	data["keys"].append(PlainScalarString(key))
	data["keys"][-1].yaml_set_anchor(host)
	return data["keys"][-1]

def add_host_rule(data, host, key_anchor):
	for rule in data["creation_rules"]:
		if rule["path_regex"] == f"secrets/{host}/.*":
			print(f"\nCreation rule for host {host} already exists. Aborting.")
			exit(1)

	data["creation_rules"].append(dict(path_regex=f"secrets/{host}/.*", age=[]))
	data["creation_rules"][-1]["age"].append(key_anchor)

def prompt_diff(old, new):
	with open(old, "r") as old, open(new, "r") as new:
		for line in unified_diff(old.readlines(), new.readlines()):
			if not line.endswith("\n"):
				line = line + "\n"
			if line.startswith("-"):
				print(f"\033[31m- {line[1:]}\033[0m", end='')  # Red for removals
			elif line.startswith("+"):
				print(f"\033[32m+ {line[1:]}\033[0m", end='')  # Green for additions
			else:
				print(f" {line}", end='')
	
	confirm = input("\nApply these changes to .sops.yaml? (y/N): ")

	if confirm.lower() != 'y':
		print("Aborting without changes.")
		sys.exit(0)

yaml = YAML()
yaml.default_flow_style = False

host = sys.argv[1]

with open(".sops.yaml", "r") as prev:
	data = yaml.load(prev.read())
     
with tempfile.TemporaryDirectory() as tmpdir:
	deployer_secrets = []
	host_secrets = []

	print(f"Generating age key pair to decrypt sops secrets...")
	subprocess.run(["age-keygen", "-o", f"{tmpdir}/{host}.key"], check=True)
	age_pub = subprocess.run(["age-keygen", "-y", f"{tmpdir}/{host}.key"], check=True, stdout=subprocess.PIPE).stdout.decode().strip()
	deployer_secrets.append(f"{host}.key")

	print("\nEnter the password for the user. Will be hashed using yescrypt.")
	with open(f"{tmpdir}/hashedPassword", "wb") as f:
		subprocess.run(["mkpasswd", "-m", "yescrypt"], check=True, stdout=f)
	host_secrets.append("hashedPassword")

	print("\nGenerating host ssh key pair...")
	subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-f", f"{tmpdir}/ssh_host_ed25519", "-N", "", "-C", ""], check=True)
	host_secrets.append("ssh_host_ed25519")

	print("\nGenerating user ssh key pair...")
	subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-f", f"{tmpdir}/id_ed25519", "-C", ""], check=True)
	host_secrets.append("id_ed25519")

	print("\nAdd the following ssh public keys to public-keys.nix")
	with open(f"{tmpdir}/ssh_host_ed25519.pub", "r") as f:
		print(f"  host.{host} = \"{f.read().strip()}\";")
	with open(f"{tmpdir}/id_ed25519.pub", "r") as f:
		print(f"  user.{host} = \"{f.read().strip()}\";")

	input("\nContinue? (press enter)")

	key_anchor = add_key(data, host, age_pub)
	add_host_rule(data, host, key_anchor)

	with open(f"{tmpdir}/.sops.yaml", "wb") as f:
		yaml.dump(data, f)

	prompt_diff(".sops.yaml", f"{tmpdir}/.sops.yaml")

	with open(".sops.yaml", "wb") as f:
		yaml.dump(data, f)

	for secret in deployer_secrets:
		subprocess.run(["mkdir", "-p", "secrets/deployer"], check=True)
		with open(f"secrets/deployer/{secret}", "wb") as f:
			subprocess.run(["sops", "--filename-override", f"secrets/deployer/{secret}", "-e", f"{tmpdir}/{secret}"], check=True, stdout=f)

	for secret in host_secrets:
		subprocess.run(["mkdir", "-p", f"secrets/{host}"], check=True)
		with open(f"secrets/{host}/{secret}", "wb") as f:
			subprocess.run(["sops", "--filename-override", f"secrets/{host}/{secret}", "-e", f"{tmpdir}/{secret}"], check=True, stdout=f)

	print("Secrets have been created. Remember to git add")

	
