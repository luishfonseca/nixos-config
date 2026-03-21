#!/usr/bin/env bash
set -euo pipefail

BOOT_DIR=/boot
CLIENT_KEY="$BOOT_DIR/unlock-client.key"
CLIENT_CERT="$BOOT_DIR/unlock-client.cert"
PEER_CERT_BOOT="$BOOT_DIR/unlock-peer.cert"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--peer-internal)
		PEER_INTERNAL="$2"
		shift 2
		;;
	--self-public)
		SELF_PUBLIC="$2"
		shift 2
		;;
	--port)
		PORT="$2"
		shift 2
		;;
	--luks-key)
		LUKS_KEY="$2"
		shift 2
		;;
	*)
		echo "Unknown: $1" >&2
		exit 1
		;;
	esac
done

PORT="${PORT:-9735}"
LUKS_KEY="${LUKS_KEY:-/recovery/root.key}"

: "${PEER_INTERNAL:?missing --peer-internal}" "${SELF_PUBLIC:?missing --self-public}"

if [[ ! -f $LUKS_KEY ]]; then
	echo "LUKS key file not found: $LUKS_KEY" >&2
	exit 1
fi

echo "peer-internal=$PEER_INTERNAL self-public=$SELF_PUBLIC port=$PORT"

echo "Generating ephemeral client cert (SAN=IP:${SELF_PUBLIC})"
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
	-keyout "$CLIENT_KEY" -out "$CLIENT_CERT" \
	-days 1 -nodes -subj "/CN=luks-unlock-ephemeral" \
	-addext "subjectAltName=IP:${SELF_PUBLIC}" 2>/dev/null

echo "Fetching peer server cert via TOFU from ${PEER_INTERNAL}:${PORT}"
openssl s_client \
	-connect "${PEER_INTERNAL}:${PORT}" \
	-cert "$CLIENT_CERT" -key "$CLIENT_KEY" \
	-showcerts </dev/null 2>/dev/null |
	openssl x509 -outform PEM >"$PEER_CERT_BOOT"

FP=$(openssl x509 -in "$CLIENT_CERT" -outform DER | sha256sum | cut -d' ' -f1)
echo "Ephemeral cert fingerprint: $FP"

TMP_KEY=$(mktemp)
trap 'rm -f "$TMP_KEY"' EXIT

echo "Registering with peer at ${PEER_INTERNAL}:${PORT} (TLS, no verify)"
curl -sfk --max-time 30 -X POST \
	"https://${PEER_INTERNAL}:${PORT}/register/${FP}" \
	-o "$TMP_KEY"
echo "Received unlock key from peer"

ROOT_DEVICE=$(cryptsetup status root_crypt | awk '/device:/{print $2}')
if [[ -z $ROOT_DEVICE ]]; then
	echo "Failed to resolve root_crypt backing device" >&2
	exit 1
fi
echo "Root device: $ROOT_DEVICE"

if cryptsetup luksDump "$ROOT_DEVICE" | grep -Eq '^[[:space:]]*7: luks2'; then
	echo "Killing existing LUKS slot 7"
	cryptsetup luksKillSlot "$ROOT_DEVICE" 7 --key-file "$LUKS_KEY"
fi

echo "Enrolling unlock key in LUKS slot 7"
cryptsetup luksAddKey "$ROOT_DEVICE" "$TMP_KEY" --key-file "$LUKS_KEY" --key-slot 7

chmod 600 "$CLIENT_KEY" "$CLIENT_CERT" "$PEER_CERT_BOOT"
echo "Done"
