# Service secrets

Only SOPS-encrypted `*.json` files belong here. Plaintext files and private
keys must never be added. The recipient is derived from this laptop's existing
`/etc/ssh/ssh_host_ed25519_key.pub`; sops-nix uses the corresponding root-owned
host key at activation. Preserve that private host key separately before any
reinstallation; this repository cannot recover it.

From the repository root, encrypt and verify existing service credentials:

```sh
sudo "$(nix build .#secrets-migrator --no-link --print-out-paths)/bin/migrate-secrets" "$PWD"
git add secrets/*.json
```

The helper never prints plaintext, checks round-trip decryption, preserves
existing ciphertext and keeps the original service files. Until migration,
modules keep using the existing paths. Once ciphertext is tracked by Git,
the next build uses `/run/secrets/*` through sops-nix. Existing passwords and
the Open WebUI signing key are preserved, not regenerated.

Do not delete the original files until decryption and service startup have
been verified on the target machine. Updating a migrated secret means editing
its ciphertext with SOPS and the host age identity on that machine.
