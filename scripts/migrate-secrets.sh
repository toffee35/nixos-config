#!/usr/bin/env bash
set -euo pipefail

repo=${1:?Usage: migrate-secrets /absolute/path/to/nixos-config}
[[ $EUID == 0 ]] || { echo "Run this command with sudo; it reads root-owned service secrets." >&2; exit 1; }
[[ -f $repo/flake.nix && -d $repo/.git ]] || { echo "Not a configuration checkout" >&2; exit 1; }
hostkey=/etc/ssh/ssh_host_ed25519_key
work=$(mktemp -d /run/nixos-secrets-migration.XXXXXX)
trap 'rm -rf "$work"' EXIT
chmod 700 "$work"
ssh-to-age -private-key -i "$hostkey" > "$work/age-key.txt"
recipient=$(ssh-to-age < "$hostkey.pub")
mkdir -p "$repo/secrets"

for entry in \
  wireguard:/etc/wireguard/private.key \
  samba:/etc/samba/container-env \
  portainer:/etc/portainer/admin-password \
  webui:/var/lib/open-webui/secret.env; do
  name=${entry%%:*}
  source=${entry#*:}
  target=$repo/secrets/$name.json
  [[ ! -e $target ]] || { echo "Preserving existing encrypted $name"; continue; }
  [[ -s $source ]] || { echo "Missing service secret: $source" >&2; exit 1; }
  sops --config "$repo/.sops.yaml" --filename-override "$target" \
    --encrypt --input-type binary --output-type binary --age "$recipient" "$source" > "$work/$name.json"
  SOPS_AGE_KEY_FILE="$work/age-key.txt" sops --decrypt --input-type binary --output-type binary "$work/$name.json" | cmp - "$source"
  install -m 0644 "$work/$name.json" "$target"
  if [[ -n ${SUDO_UID:-} && -n ${SUDO_GID:-} ]]; then
    chown "$SUDO_UID:$SUDO_GID" "$target" "$repo/secrets"
  fi
  echo "Encrypted and verified: $name"
done
echo "Original files preserved. Add secrets/*.json to Git, rebuild, and keep the host SSH key safe."
