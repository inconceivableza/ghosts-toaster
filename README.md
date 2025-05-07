# Ghosts-Toaster

This project is designed to use [Ghost](https://ghost.org/) as a nice usable frontend for editing multiple static websites,
which don't require the subscriber management and other dynamic features that Ghost provides,
by hosting Ghost for multiple of these websites on a single machine,
and then [publishing the generated content to static files](https://github.com/SimonMo88/ghost-static-site-generator/) that can be deployed elsewhere.

Ghost itself only supports running a single site on a host, so Docker containers are used for the different Ghost sites.
[Caddy](https://caddyserver.com/) is used as a front-end server that also generates SSL certificates for each domain.

_Many ghosts need static hosts_ \
_With reasonable performance_ \
_Take those ghosts and make them toast_ \
_To serve up to your audience_

This guide will walk you through setting up and managing multiple Ghost websites on a single host using Docker Compose and Caddy.

## Initial Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/inconceivableza/ghosts-toaster.git
   cd ghosts-toaster
   ```

2. **Create environment file from example**:
   ```bash
   cp ghosts-toaster.env.example .env
   ```
   
   Edit the `.env` file to set your global configuration, mail settings, etc.
   The setup script will automatically generate a mysql password and web token.
   By default, it's set to serve up the dynamic sites at `ghost.$SITE_DOMAIN` and the static sites at `www.$SITE_DOMAIN`
   If you prefer to serve the static sites via a CDN etc, then adjust the prefixes in this file.
   There are also options for how frequently [watchtower](https://containrrr.dev/watchtower/) should update the software, and where to send its email updates.

3. **Run the setup script**:
   ```bash
   ./setup.sh
   ```
   
   This will start the Docker containers.but no sites as yet will be available until you create them.

## Adding a New Site

Use the provided script:

```bash
./scripts/create-site.sh <site_name> <domain>
# Example: ./scripts/create-site.sh myblog myblog.com

# Apply changes
docker compose up -d
```

After your site is running, follow the instructions provided by the script to:
1. Set up the webhook for automatic static site generation
2. Configure the GitHub repository for the static site

## Automatic Static Site Generation

Ghosts-Toaster includes a webhook system that automatically rebuilds the static site when content changes:

1. Each site uses a webhook that triggers on the `site.changed` event
2. The webhook notifies a webhook receiver container running internally in the Docker network
3. The webhook receiver triggers the static site generator for the specific site
4. Changes are automatically committed to Git and pushed to GitHub

The system handles concurrent updates intelligently:
- If a site generation is already running when a new update arrives, the update is queued
- If multiple updates arrive while a generation is running, they are combined into a single update
- This ensures efficient processing without unnecessary duplicate builds

## Git Integration

Each static site is automatically managed in its own Git repository:

1. A Git repository is initialized in the static site directory
2. All changes are automatically committed with timestamped messages
3. If a remote is configured, changes are automatically pushed

To set up GitHub integration for your static site:

1. Create a new repository on GitHub named after your domain
2. Follow the instructions provided after site creation to configure the remote
   - This uses a [deploy key](https://docs.github.com/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys)
     rather than using your personal SSH keys to facilitate pushing commits
     An alternative is to set up a
     [GitHub App](https://docs.github.com/apps/overview).
3. Consider setting up GitHub Pages, Netlify or CloudFlare to host your static site directly from the repository

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

### Git Issues

If commits or pushes are failing:

```bash
cd static/yourdomain.com
git status
git remote -v
```

Ensure the remote is properly configured and you have the necessary permissions.

## Customizing Your Setup

### Custom Themes

Add a volume mount in the site-template.yml file:
```yaml
volumes:
  - ghost_content_${SITE_NAME}:/var/lib/ghost/content
  - ./sites/${SITE_DOMAIN}/themes:/var/lib/ghost/content/themes
```

### Email Configuration

All sites share the same email configuration defined in the global `.env` file:

```bash
# Shared mail configuration
MAIL_TRANSPORT=SMTP
MAIL_SERVICE=Mailgun
MAIL_USER=postmaster@example.com
MAIL_PASSWORD=your_mail_password
```

Ghost uses this configuration for transactional email (user sign-up etc;
obviously how this works in a static site may be different).

For sending newsletters, it uses a different email setup with the Mailgun API;
if you want to use this, it must be [configured manually for each site in the Ghost settings](https://ghost.org/docs/faq/mailgun-newsletters/).


## Security Considerations

1. Use strong passwords (automatically handled by the site creation script)
2. Set a secure webhook secret in `.env`
3. Keep all containers updated (watchtower is configured to do this)
4. Regularly back up your data
5. Use a firewall to restrict access to necessary ports only

## Performance Considerations

The static site generation will impose a greater load each time something changes in the site,
but allows for much more efficient serving of the site, particularly if there is high load
(as well as serving from a different host or CDN).

See these references for how many ghost instances could be served from a single server:

- [Multiple Ghost Instances on Digital Ocean Droplet](https://jazmy.medium.com/multiple-ghosts-instances-on-digital-ocean-droplet-43079693aa09)
- [Filling up a 1GB server with a stack of Ghost blogs](https://techroads.org/filling-up-a-1gb-server-with-a-stack-of-ghost-blogs/) which estimates 65MB RAM per Ghost container, with a base of 150MB (I haven't checked this)

Thanks to Joel Duncan for [Host Multiple Ghost Instances with Docker](https://joelduncan.io/docker-multiple-ghost-instances/)

## License

The project is licensed under the [MIT license](./LICENSE)
