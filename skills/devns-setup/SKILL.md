---
name: devns-setup
description: Explains DevNS.me usage and scaffolds a local Docker + Traefik dev environment with custom domains and HTTPS. Use when the user asks about DevNS.me, wants to set up Traefik as a reverse proxy, or wants to create a new project that routes by domain (Mode 1 .localhost, Mode 2 .devns.me, Mode 3 custom-domain HTTPS) following the DevNS-me/devns-example layout.
---

# DevNS.me Setup

Help developers (1) understand DevNS.me and (2) scaffold a Docker + Traefik dev
environment where multiple projects run at once and route by domain name. Each
project is always reachable locally via **Mode 1** (`.localhost`) and, through
the single `APP_DOMAIN_LAN` variable, via **either Mode 2** (`.devns.me`, HTTP)
**or Mode 3** (custom domain + HTTPS) — Modes 2 and 3 are alternatives, not three
simultaneous routes. Files are downloaded from the published example repo
`DevNS-me/devns-example`, mirroring its current layout (the file list is fixed,
so brand-new upstream files are not picked up automatically).

**Prerequisites**: Docker + Docker Compose, `curl`, network access, and free
ports `80`/`443`/`8080`. The `PROXY_NETWORK` value must match across Traefik and
every project. Validate a stack with `docker compose config` before `up`.

`$SKILL_DIR` below = the directory this SKILL.md lives in (it contains `scripts/`
and `references/`). Replace it with the skill's real base directory path (the
harness provides it) — it is not a preset shell variable.

## 1. Answering questions about DevNS.me

For any conceptual/usage/troubleshooting question, read
[references/devns-overview.md](references/devns-overview.md) and answer from it.
For Mode 3 / HTTPS / certificate specifics, read
[references/enabling-https.md](references/enabling-https.md).

## 2. Scaffolding workflow

Always confirm paths and names with the user before writing files — never assume.
Run the bundled scripts (they download from raw GitHub and never overwrite an
existing `.env`). Copy this checklist and work through it:

```
- [ ] Step A: Decide whether Traefik is needed and where
- [ ] Step B: Set up Traefik (only if needed)
- [ ] Step C: Decide project location and slug
- [ ] Step D: Scaffold the project + confirm .env variables
- [ ] Step E: Tell the user it is ready to edit
```

### Step A — Traefik: needed? where?

Check the current working directory **and its parent** for an existing Traefik
project — a folder named `traefik`, `*-traefik`, or `traefik-*`:

```bash
ls -d ./*traefik* ../*traefik* 2>/dev/null
```

- If one is found, Traefik is likely already installed → **do not reinstall**.
  Still ask the user to confirm it is the running proxy.
- If none is found, **ask the user whether Traefik needs to be installed and
  where**, proposing `./traefik` as the default path. Let them confirm or change it.
- Note: if the project will live in the current directory, Traefik may belong in
  the **parent** folder. In that case still ask whether it already exists rather
  than installing a duplicate.

### Step B — Set up Traefik (only if Step A says so)

```bash
sh "$SKILL_DIR/scripts/setup-traefik.sh" <confirmed_traefik_path>
```

This downloads `docker-compose.yml`, `.env.template`, `.docker/traefik/setup-certs.sh`
and `tls.yml.template`, and creates `.env` from the template. The default `.env`
works for HTTP / `.localhost`; HTTPS cert URLs are only needed for Mode 3.

Start it: `cd <traefik_path> && docker compose up -d` (dashboard: http://localhost:8080).

> **Security note**: this is a local-dev setup. Traefik mounts the Docker socket
> and serves an unauthenticated dashboard on `:8080` over plain HTTP; the cert/key
> URLs in `traefik/.env` (and in the helper logs) carry a secret token — treat
> them as credentials and do not share `.env` or those logs.

### Step C — Project location and slug

Ask the user where the new project goes and confirm the **slug** (used in domains):

- **New subfolder** (default): files go in `./<slug>/`. Confirm the folder name.
- **Current directory**: the user already created/entered the project folder.
  Use the **current folder name as the slug** (confirm it). Files are written to `.`.

### Step D — Scaffold the project

The script writes **placeholder** values; show the user the variables it will
create, gather their real LAN IP (and custom domain for `https`), and tell them
they must edit `.env` after scaffolding. The template defines:

| Variable | Meaning |
| --- | --- |
| `APP_DOMAIN` | Mode 1 — `<slug>.localhost` |
| `APP_DOMAIN_LAN` | `http` mode → Mode 2: `<slug>-192-168-1-10.devns.me` · `https` mode → Mode 3: `<slug>-192-168-1-10.example.com` (replace the dashed LAN IP, and the custom domain for Mode 3) |
| `PROXY_NETWORK` | Traefik network, default `traefik_network` |

Then scaffold (default `http` = Mode 1 + Mode 2):

```bash
sh "$SKILL_DIR/scripts/setup-project.sh" <dest_dir> <slug>
```

For a project that needs HTTPS from the start (Mode 1 + Mode 3, custom domain):

```bash
sh "$SKILL_DIR/scripts/setup-project.sh" <dest_dir> <slug> https
```

Mode 3 is **optional**: scaffold `http` now and explain that HTTPS can be added
later — see [references/enabling-https.md](references/enabling-https.md) (own a
domain, delegate to DevNS.me, add cert URLs to `traefik/.env`, add the TLS labels).

If the destination is not already a git repo with `*.env` ignored, suggest adding
`.env` to `.gitignore` (it holds local-only values).

### Step E — Done

Tell the user everything is ready to be edited. Point them to:

- `<traefik_path>/.env` — Traefik config / HTTPS cert URLs (Mode 3 only).
- `<project>/.env` — set the real dashed LAN IP (and custom domain for Mode 3).
- `<project>/docker-compose.yml` — replace the example `traefik/whoami` image with
  the real application and adjust `loadbalancer.server.port` to the app's port.

Start order: Traefik first, then `cd <project> && docker compose up -d`.
