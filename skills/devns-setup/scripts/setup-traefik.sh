#!/bin/sh
# ============================================================================
# DevNS.me — Traefik setup
# Downloads the Traefik reverse-proxy project from the devns-example repo
# into a destination directory and prepares its .env file.
#
# Usage:   sh setup-traefik.sh <dest_dir>
# Example: sh setup-traefik.sh ./traefik
#
# Override source (advanced):
#   DEVNS_RAW_BASE   base raw URL (default: GitHub main branch)
# ============================================================================
set -eu

DEST="${1:-}"
if [ -z "$DEST" ]; then
  echo "Usage: sh setup-traefik.sh <dest_dir>" >&2
  exit 2
fi

RAW_BASE="${DEVNS_RAW_BASE:-https://raw.githubusercontent.com/DevNS-me/devns-example/main}"

# Files that make up the Traefik project (paths relative to repo root and to DEST)
FILES="
docker-compose.yml
.env.template
.docker/traefik/setup-certs.sh
.docker/traefik/tls.yml.template
"

echo "==> Setting up Traefik in: $DEST"
echo "    Source: $RAW_BASE/traefik"
echo ""

# Guard: never silently overwrite an existing Traefik scaffold. Re-run with
# FORCE=1 to allow overwriting the downloaded files (.env is always kept).
for f in $FILES; do
  if [ -e "$DEST/$f" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "    ✗ $DEST/$f already exists — re-run with FORCE=1 to overwrite" >&2
    exit 1
  fi
done

for f in $FILES; do
  src="$RAW_BASE/traefik/$f"
  out="$DEST/$f"
  mkdir -p "$(dirname "$out")"
  echo "    downloading $f"
  if ! curl -fsSL "$src" -o "$out"; then
    echo "    ✗ Failed to download $src" >&2
    exit 1
  fi
done

# Note: setup-certs.sh does not need the executable bit — Traefik's compose
# invokes it as `sh /scripts/setup-certs.sh`.

# Prepare .env from template (never overwrite an existing .env)
if [ -f "$DEST/.env" ]; then
  echo ""
  echo "    .env already exists — left untouched"
else
  cp "$DEST/.env.template" "$DEST/.env"
  echo ""
  echo "    created .env from .env.template"
fi

echo ""
echo "==> Traefik ready in $DEST"
echo "    Start it with:  cd \"$DEST\" && docker compose up -d"
echo "    Dashboard:      http://localhost:8080"
