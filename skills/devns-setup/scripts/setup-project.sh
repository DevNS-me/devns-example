#!/bin/sh
# ============================================================================
# DevNS.me — New project scaffold
# Downloads a project template from the devns-example repo into a destination
# directory and rewrites it for your project slug.
#
# Usage:   sh setup-project.sh <dest_dir> <slug> [mode]
#   dest_dir  where to write the files (e.g. ./myapp  or  .  for current dir)
#   slug      project name used in domains (e.g. myapp)
#   mode      http  (default) -> Mode 1 (.localhost) + Mode 2 (.devns.me)
#             https           -> Mode 1 (.localhost) + Mode 3 (custom domain, TLS)
#
# Example: sh setup-project.sh ./myapp myapp
#          sh setup-project.sh ./myapp myapp https
#
# Override source (advanced):
#   DEVNS_RAW_BASE   base raw URL (default: GitHub main branch)
# ============================================================================
set -eu

DEST="${1:-}"
SLUG="${2:-}"
MODE="${3:-http}"

if [ -z "$DEST" ] || [ -z "$SLUG" ]; then
  echo "Usage: sh setup-project.sh <dest_dir> <slug> [http|https]" >&2
  exit 2
fi

# Validate slug as a DNS label (lowercase letters, digits, hyphens; no leading/
# trailing hyphen; max 63 chars). This keeps the generated hostnames valid and
# makes the slug safe to use in the sed substitution below.
case "$SLUG" in
  *[!a-z0-9-]* | -* | *- | "")
    echo "Invalid slug '$SLUG': use lowercase letters, digits and hyphens (a DNS label)." >&2
    exit 2 ;;
esac
if [ "${#SLUG}" -gt 63 ]; then
  echo "Invalid slug '$SLUG': must be at most 63 characters." >&2
  exit 2
fi

case "$MODE" in
  http)  TEMPLATE="project1" ;;   # Mode 1 + Mode 2 (HTTP, .devns.me)
  https) TEMPLATE="project2" ;;   # Mode 1 + Mode 3 (custom domain + TLS)
  *) echo "Unknown mode: $MODE (use 'http' or 'https')" >&2; exit 2 ;;
esac

RAW_BASE="${DEVNS_RAW_BASE:-https://raw.githubusercontent.com/DevNS-me/devns-example/main}"

echo "==> Scaffolding project '$SLUG' (mode: $MODE) in: $DEST"
echo "    Based on template: $TEMPLATE"
echo ""

mkdir -p "$DEST"

# Guard: never silently overwrite an existing scaffold. Re-run with FORCE=1 to
# allow overwriting docker-compose.yml / .env.template (.env is always kept).
for f in docker-compose.yml .env.template; do
  if [ -e "$DEST/$f" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "    ✗ $DEST/$f already exists — re-run with FORCE=1 to overwrite" >&2
    exit 1
  fi
done

for f in docker-compose.yml .env.template; do
  src="$RAW_BASE/$TEMPLATE/$f"
  echo "    downloading $f"
  if ! curl -fsSL "$src" -o "$DEST/$f"; then
    echo "    ✗ Failed to download $src" >&2
    exit 1
  fi
done

# Rewrite the template slug (project1/project2) -> chosen slug, in the .env template.
# docker-compose.yml uses ${COMPOSE_PROJECT_NAME}/${APP_DOMAIN} and needs no edit.
sed -e "s/project1/$SLUG/g" -e "s/project2/$SLUG/g" \
  "$DEST/.env.template" > "$DEST/.env.template.tmp"
mv "$DEST/.env.template.tmp" "$DEST/.env.template"

# Prepare .env from the rewritten template (never overwrite an existing .env)
if [ -f "$DEST/.env" ]; then
  echo ""
  echo "    .env already exists — left untouched"
else
  cp "$DEST/.env.template" "$DEST/.env"
  echo ""
  echo "    created .env from .env.template (slug: $SLUG)"
fi

echo ""
echo "==> Project '$SLUG' ready in $DEST"
echo "    Next: edit $DEST/.env (set your local IP / domain), then:"
echo "          cd \"$DEST\" && docker compose up -d"
