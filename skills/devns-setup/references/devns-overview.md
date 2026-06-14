# DevNS.me — Overview & Access Modes

Use this reference to answer questions about how DevNS.me works and how the
Docker + Traefik example is structured. Source of truth:
https://github.com/DevNS-me/devns-example (README.md).

## What is DevNS.me?

A DNS utility service for developers (inspired by xip.io, nip.io, traefik.me):

- **Wildcard DNS** — embed an IP in a subdomain: `192-168-1-10.devns.me` → `192.168.1.10`.
- **Custom domains** — delegate your own domain (e.g. `example.com`) to DevNS.me nameservers.
- **HTTPS certificates** — automatic Let's Encrypt issuance for custom domains via DNS-01.
- **LAN access** — reach your projects from any device on your network.

Portals: website https://devns.me — account/domains https://account.devns.me

## Why Traefik + this layout?

One Traefik reverse proxy routes traffic to many projects **by domain name**, so
multiple projects run at once with no port conflicts (no `:3000` / `:8080` clashes).
Each project is a `docker-compose.yml` that joins Traefik's external proxy network
and declares routing via labels. Add a project by creating a new compose file.

## Repository layout

```
traefik/              # the reverse proxy (start this first)
  docker-compose.yml
  .env.template       # copy to .env (PROXY_NETWORK + HTTPS cert URLs)
  .docker/traefik/
    setup-certs.sh    # auto-downloads certs and generates tls.yml
    tls.yml.template
project1/             # Mode 1 + Mode 2 (HTTP)
project2/             # Mode 1 + Mode 3 (HTTPS, custom domain)
```

Every directory uses a `.env.template` copied to `.env` (the `.env` is gitignored).

## The three access modes

A project's `.env` defines two domains: `APP_DOMAIN` (local) and `APP_DOMAIN_LAN`
(LAN). The `docker-compose.yml` labels reference them.

### Mode 1 — `.localhost` (local machine only)
- `APP_DOMAIN=myproject.localhost`
- URL: `http://myproject.localhost` — your computer only, no HTTPS.

### Mode 2 — `.devns.me` (HTTP, LAN-accessible)
- `APP_DOMAIN_LAN=myproject-192-168-1-10.devns.me`
- `192-168-1-10` is your local IP in **dashed format** (dots → dashes).
- URL: `http://myproject-192-168-1-10.devns.me` — any device on the LAN, no cert.

### Mode 3 — custom domain (HTTP + HTTPS, LAN-accessible)
- Requires owning a domain delegated to DevNS.me and a downloaded certificate.
- `APP_DOMAIN_LAN=myproject-192-168-1-10.example.com`
- URLs: `http(s)://myproject-192-168-1-10.example.com`.
- See [enabling-https.md](enabling-https.md) for the full setup.

> Only **dashed-format** hosts work with the wildcard certificates.
> `myproject.192.168.1.10.example.com` (dots) will NOT match; use dashes.

## Find your local IP (for dashed format)

```bash
hostname -I            # Linux
ipconfig getifaddr en0 # macOS
ipconfig               # Windows -> "IPv4 Address"
# Convert 192.168.1.10 -> 192-168-1-10
```

## Why HTTPS in local dev?

Mode 3 gives a real certificate on a real custom domain, useful for testing
OAuth/SAML/OpenID redirects, payment SDKs (Stripe, PayPal, Apple Pay), and MCP
servers under realistic HTTPS conditions.

Two clarifications:

- Browsers already treat `http://localhost` (Mode 1) as a **secure context**, so
  Service Workers/PWA, camera, geolocation, WebAuthn, Clipboard, etc. work over
  plain HTTP on localhost — Mode 3 is not required just to exercise those APIs.
- Mode 2/3 hosts resolve to a **private LAN IP**, so they are reachable from your
  network but **not from the public internet**. Inbound webhooks from external
  services need a public tunnel (e.g. ngrok), not DevNS.me alone.

## Troubleshooting (quick)

- Traefik running? `docker ps | grep traefik` · logs `docker logs traefik-traefik-1`
- Network exists? `docker network ls | grep traefik_network`
- HTTPS issues? `docker logs traefik-traefik-https-helper-1` (look for "✓ downloaded");
  ensure dashed-format host; `cd traefik && docker compose restart` after cert changes.
- DNS fails to resolve `*.devns.me`? Use Google DNS `8.8.8.8` / `8.8.4.4`;
  test `nslookup 192-168-1-10.devns.me 8.8.8.8`.
