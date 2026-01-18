# DevNS.me Example Setup

This repository contains a Docker-based example setup demonstrating how to integrate [DevNS.me](https://devns.me) with Traefik for local development with automatic HTTPS certificates using your custom domain.

## What is DevNS.me?

[DevNS.me](https://devns.me) is a next-generation development DNS utility service that provides wildcard DNS resolution, custom domain delegation, and automatic HTTPS certificate provisioning. It allows developers to use structured hostnames that resolve to IP addresses without managing DNS servers or certificates manually.

For detailed information about DevNS.me features, pricing, and documentation, visit [devns.me](https://devns.me).

## Setting Up Custom Domains with DevNS.me and Traefik

This repository demonstrates how to integrate DevNS.me with Traefik to create a local development environment with full HTTPS support using your own custom domain.

### Example Structure

```
devns-example/
├── .gitignore
├── project1/
│   ├── docker-compose.yml
│   └── .env.template
├── project2/
│   ├── docker-compose.yml
│   └── .env.template
└── traefik/
    ├── docker-compose.yml
    ├── .env.template
    └── .docker/
        └── traefik/
            └── tls.yml
```

*Note: Copy `.env.template` files to `.env` and customize them with your actual values before running.*

### Components

#### Traefik (Reverse Proxy)

- **File**: `traefik/docker-compose.yml`
- **Role**: Reverse proxy with integrated HTTPS support
- **Certificates**: Automatically downloaded from devns.me using your provided token
- **Configuration**: Supports hostname-based routing with TLS

#### Example Projects

- **project1** and **project2**: `traefik/whoami` containers for demonstration
- **Routing**: Configured to respond on local domains and devns.me custom domains
- **HTTPS**: Supported for delegated devns.me domains
