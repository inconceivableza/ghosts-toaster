# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ghosts-Toaster is a multi-site Ghost CMS platform that automatically generates and deploys static sites. It uses Docker containers to host multiple Ghost instances on a single server, with automatic static site generation triggered by webhooks.

## Architecture

- **Ghost Instances**: Each site runs in its own Docker container (`ghost_<sitename>`)
- **Caddy**: Front-end web server with automatic SSL certificate generation
- **MySQL**: Shared database for all Ghost instances
- **Webhook System**: Node.js webhook receiver that triggers static site generation
- **Static Generator**: Container running a fork of [ghost-static-site-generator](https://github.com/SimonMo88/ghost-static-site-generator/) (abbreviated as gssg) at [inconceivableza/ghosts-toaster-site-generator](https://github.com/inconceivableza/ghosts-toaster-site-generator). This uses wpull rather than wget for site retrieval. The fork of gssg should be recorded as part of this project and worked on simulataneously; the code is checked out in `ghosts-toaster-site-generator`.
- **Watchtower**: Automatic container updates

## Key Commands

### Site Management
```bash
# Create a new site
./scripts/create-site.sh <site_name> <domain>

# Apply Docker Compose changes
docker compose up -d

# Regenerate all site configurations
./scripts/generate-site-config.sh

# Manual static site generation for all sites
./scripts/generate-static-sites.sh
```

### Development and Debugging
```bash
# View container logs
docker compose logs <service_name>
docker compose logs webhook-receiver
docker compose logs static-generator

# Check container status
docker compose ps

# Execute commands in containers
docker exec -it webhook-receiver sh
docker exec -it static-generator sh

# Access MySQL database
./scripts/exec-mysql
```

### Backup and Maintenance
```bash
# Backup all sites (databases and content)
./scripts/backup-ghosts.sh

# Update Ghost version (edit site-template.yml first)
./scripts/generate-site-config.sh && docker compose up -d
```

### Webhook Development
```bash
# Install webhook dependencies
cd webhook && npm install

# Start webhook server locally (for development)
cd webhook && npm start
```

## Configuration Files

- **Main configuration**: `.env` (created from `ghosts-toaster.env.example`)
- **Site template**: `site-template.yml` (used to generate individual site configs)
- **Site-specific configs**: Generated in `include-sites.yml`
- **Individual site settings**: `sites/<domain>/site.env`

## Static Site Generation Flow

1. Content change in Ghost triggers webhook
2. Webhook receiver validates signature and identifies site
3. Static generator runs `gssg` tool to create static files
4. Git repository is updated with changes
5. Changes are automatically pushed to remote (if configured)

## Directory Structure

- `/sites/` - Site-specific configuration files
- `/static/` - Generated static sites (each in own Git repo)
- `/webhook/` - Node.js webhook receiver application
- `/scripts/` - Shell scripts for site management
- `/caddy-sites/` - Generated Caddy configuration files

## Git Integration

Each static site maintains its own Git repository in `/static/<domain>/`. The system automatically:
- Initializes Git repos for new sites
- Commits changes after static generation
- Pushes to configured remotes using deploy keys
- Handles SSH configuration for multiple repositories

## Security Notes

- Webhook signatures are validated using `WEBHOOK_SECRET`
- Deploy keys are used for Git operations (stored in `/ssh/`)
- Internal webhook network isolates webhook receiver
- MySQL uses native password authentication
