# Enabling Mode 3 (HTTPS with a custom domain)

A project scaffolded in `http` mode supports Mode 1 (`.localhost`) and Mode 2
(`.devns.me`, HTTP only). Mode 3 adds HTTPS over a **custom domain** you own.

Two ways to get a Mode 3 project:

- **Fresh project**: scaffold directly with HTTPS labels —
  `sh scripts/setup-project.sh <dest> <slug> https`
  (this uses the `project2` template, which already includes the TLS router).
- **Upgrade an existing `http` project**: follow the steps below.

## Requirements

1. **Own a domain** — a second-level domain (`example.com`) or a subdomain
   (`dev.example.com`).
2. **Delegate it to DevNS.me nameservers**:
   - Second-level domain → set registrar nameservers to `ns1.devns.me` / `ns2.devns.me`.
   - Subdomain → add NS records in your zone:
     ```
     dev.example.com.  IN  NS  ns1.devns.me.
     dev.example.com.  IN  NS  ns2.devns.me.
     ```
3. **Register the domain** at https://account.devns.me → "Add Domain".
4. **Get the certificate URLs** — click the `certificate.crt` and `private.key`
   buttons (the full URLs, including the security token, are copied to clipboard).

## Step 1 — Point the project at your custom domain

In the project's `.env`, set `APP_DOMAIN_LAN` to the dashed-format custom host:

```env
APP_DOMAIN_LAN=myproject-192-168-1-10.example.com
```

## Step 2 — Add the HTTPS router to docker-compose.yml

Ensure the service labels include a TLS router (this is what the `project2`
template provides). Add the two `-https` labels alongside the existing ones:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.${COMPOSE_PROJECT_NAME}.rule=Host(`${APP_DOMAIN}`) || Host(`${APP_DOMAIN_LAN}`)
  - traefik.http.routers.${COMPOSE_PROJECT_NAME}-https.rule=Host(`${APP_DOMAIN_LAN}`)
  - traefik.http.routers.${COMPOSE_PROJECT_NAME}-https.tls=true
  - traefik.http.services.${COMPOSE_PROJECT_NAME}.loadbalancer.server.port=80
```

## Step 3 — Add the certificate to Traefik

In `traefik/.env`, add one certificate/key pair per domain. Increment the number
for additional domains; the helper auto-detects all pairs and builds `tls.yml`:

```env
HTTPS_CERT_URL_1=https://cert.devns.me/{TOKEN}/certificate.crt
HTTPS_KEY_URL_1=https://cert.devns.me/{TOKEN}/private.key

# additional domains:
HTTPS_CERT_URL_2=https://cert.devns.me/{TOKEN2}/certificate.crt
HTTPS_KEY_URL_2=https://cert.devns.me/{TOKEN2}/private.key
```

## Step 4 — Restart Traefik and (re)start the project

```bash
cd traefik && docker compose down && docker compose up -d
cd ../myproject && docker compose up -d
```

The helper downloads the certs, generates `tls.yml`, and Traefik serves HTTPS at
`https://myproject-192-168-1-10.example.com`.

## Verify

```bash
docker logs traefik-traefik-https-helper-1     # expect "✓ Successfully downloaded"
docker exec traefik-traefik-1 cat /etc/traefik/tls.yml
```

> The helper logs print the full cert/key URLs, which include your secret token.
> Treat that output as a credential — do not paste it into issues or share it.
