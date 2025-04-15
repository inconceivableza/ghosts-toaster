# Ghosts-Toaster: Usage Guide

This guide will walk you through setting up and managing multiple Ghost websites on a single host using Docker Compose and Caddy.

## Initial Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/ghosts-toaster.git
   cd ghosts-toaster
   ```

2. **Create environment file from example**:
   ```bash
   cp ghosts-toaster.env.example ghosts-toaster.env
   ```
   
   Edit the `ghosts-toaster.env` file to set your global configuration, mail settings, and webhook secret.

3. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   
   This will create an example site, start the Docker containers, and generate the static site.

4. **Access your first site**:
   - Ghost admin: https://ghost.mysite.social/ghost/
   - Public site: https://mysite.social

## Adding a New Site

Use the provided script:

```bash
./scripts/create-site.sh <site_name> <domain>
# Example: ./scripts/create-site.sh myblog myblog.com

# Apply changes
docker compose up -d
```

After your site is running, follow the instructions provided by the script to set up the webhook for automatic static site generation.

## Automatic Static Site Generation

Ghosts-Toaster includes a webhook system that automatically rebuilds the static site when content changes:

1. Each site uses a webhook that triggers on the `site.changed` event
2. The webhook notifies a webhook receiver container running internally in the Docker network
3. The webhook receiver triggers the static site generator for the specific site

This means your static sites will be updated automatically without manual intervention whenever:
- New content is published
- Existing content is updated
- Content is deleted
- Site settings are changed

## Managing Your Sites

### Updating Ghost

Edit the `site-template.yml` file to update the Ghost image version, then run:
```bash
./scripts/generate-site-config.sh
docker compose up -d
```

### Manual Static Site Regeneration

If needed, you can manually trigger static site generation:

```bash
./scripts/generate-static-sites.sh
```

### Backing Up Your Sites

Use the provided backup script:

```bash
chmod +x scripts/backup-ghosts.sh
./scripts/backup-ghosts.sh
```

This will create backups of all MySQL databases and Ghost content volumes in a dated directory under `backups/`.

To automate backups, set up a cron job:
```bash
# Backup all sites daily at 2 AM
0 2 * * * /path/to/your/project/scripts/backup-ghosts.sh
```

## Troubleshooting

### Site Not Loading

Check container status and logs:
```bash
docker compose ps
docker compose logs caddy
docker compose logs ghost_mysite
```

### Static Site Not Updating

Check the webhook receiver and static generator logs:
```bash
docker compose logs webhook-receiver
docker compose logs static-generator
```

Verify the webhook is properly configured in Ghost admin panel (Settings > Integrations).

### Database Connection Issues

```bash
docker compose logs mysql
cat sites/mysite.social/site.env
docker exec -it mysql mysql -uroot -p
```

## Customizing Your Setup

### Custom Themes

Add a volume mount in the site-template.yml file:
```yaml
volumes:
  - ghost_content_${SITE_NAME}:/var/lib/ghost/content
  - ./sites/${SITE_DOMAIN}/themes:/var/lib/ghost/content/themes
```

### Email Configuration

All sites share the same email configuration defined in the global `ghosts-toaster.env` file:

```bash
# Shared mail configuration
MAIL_TRANSPORT=SMTP
MAIL_SERVICE=Mailgun
MAIL_USER=postmaster@example.com
MAIL_PASSWORD=your_mail_password
```

## Security Considerations

1. Use strong passwords (automatically handled by the site creation script)
2. Set a secure webhook secret in `ghosts-toaster.env`
3. Keep all containers updated
4. Regularly back up your data
5. Use a firewall to restrict access to necessary ports only