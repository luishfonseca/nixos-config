#!/usr/bin/env bash
set -euo pipefail

: "${TAILSCALE_CLIENT_ID:?must be set}"
: "${TAILSCALE_CLIENT_SECRET:?must be set}"
EXPIRY=${1:?usage: write-initrd-tailscale-key <expiry-seconds>}

echo "Fetching OAuth access token..."
TOKEN_RESPONSE=$(curl -s -X POST \
	-d "client_id=${TAILSCALE_CLIENT_ID}" \
	-d "client_secret=${TAILSCALE_CLIENT_SECRET}" \
	"https://api.tailscale.com/api/v2/oauth/token")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
	echo "Failed to get OAuth access token:" >&2
	echo "$TOKEN_RESPONSE" >&2
	exit 1
fi

TAG="tag:$(hostname)-init"
echo "Generating ephemeral authkey for ${TAG}..."
RESPONSE=$(curl -s -X POST \
	-H "Authorization: Bearer ${ACCESS_TOKEN}" \
	-H "Content-Type: application/json" \
	-d "$(jq -n --arg tag "$TAG" --argjson expiry "$EXPIRY" '{
		capabilities: {
			devices: {
				create: {
					reusable: false,
					ephemeral: true,
					preauthorized: true,
					tags: [$tag]
				}
			}
		},
		expirySeconds: $expiry
	}')" \
	"https://api.tailscale.com/api/v2/tailnet/-/keys")

KEY=$(echo "$RESPONSE" | jq -r .key)

if [ -z "$KEY" ] || [ "$KEY" = "null" ]; then
	echo "Failed to generate authkey:" >&2
	echo "$RESPONSE" >&2
	exit 1
fi

echo -n "$KEY" >/boot/tailscale-initrd-authkey
chmod 600 /boot/tailscale-initrd-authkey
echo "Authkey written. Remote unlock available on next boot."
