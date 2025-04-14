# Multi-Ghost Hosting Platform: Usage Guide

This guide will walk you through setting up and managing multiple Ghost websites on a single host using Docker Compose and Caddy.

## Initial Setup

1. **Clone the repository or create the project structure as shown**

2. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   
   This will:
   - Create the necessary directories
   - Copy template files
   - Set up an example site (mysite.social)
   - Generate site configurations
   - Start the Docker containers
   - Generate static sites

3. **Access your first site**:
   - Ghost admin: https://ghost.mysite.social/ghost/
   - Public site: https://mysite.social

## Adding a New Site

1. **Create a new directory under `sites/` with the domain name**:
   ```bash
   mkdir -p sites/newsite.com
   ```

2. **Create a .env file in that directory**:
   ```bash
   cp sites/mysite.social/.env sites/newsite.com/.env
   ```

3. **Edit the .env file with the new site's details**:
   ```bash
   # Site information
   SITE_NAME=newsite
   SITE_DOMAIN=newsite.com
   
   # Database configuration
   DB_USER=ghost_newsite
   DB_PASSWORD=secure_password_here
   DB_NAME=ghost_newsite
   
   # Mail configuration (optional)
   MAIL_TRANSPORT=SMTP
   MAIL_SERVICE=Mailgun
   MAIL_USER=postmaster@newsite.com
   MAIL_PASSWORD=your_mail_password
   
   # Static site generation configuration
   STATIC_SITE_OUTPUT_DIR=/var/www/static/newsite.com
   ```

4. **Generate the site configuration**:
   ```bash
   ./scripts/generate-site-config.sh
   ```

5. **Restart the system to apply changes**:
   ```bash
   docker compose up -d
   ```

6. **Generate the static site**:
   ```bash
   ./scripts/generate-static-sites.sh
   ```

## Managing Your Sites

### Updating Ghost

To update Ghost for all sites:

1. Edit the `docker-compose.yml` file to update the Ghost image version
2. Run:
   ```bash
   docker compose pull
   docker compose up -d
   ```

### Regenerating Static Sites

You can regenerate static sites after content updates:

```bash
./scripts/generate-static-sites.sh
```

To automate this, consider setting up a cron job:

```bash
# Regenerate static sites every hour
0 * * * * /path/to/your/project/scripts/generate-static-sites.sh
```

### Backing Up Your Sites

To back up all Ghost content and databases:

```bash
# Create backup directory
mkdir -p backups/$(date +%Y-%m-%d)

# Back up MySQL data
docker exec mysql mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases > backups/$(date +%Y-%m-%d)/all-databases.sql

# Back up Ghost content volumes
docker run --rm -v multi-ghost-server_ghost_content_mysite:/source -v $(pwd)/backups/$(date +%Y-%m-%d)/ghost_content_mysite:/backup alpine tar -czf /backup/content.tar.gz -C /source .
```

You can create a script for this and set it up as a cron job for regular backups.

### Monitoring

You can monitor the health of your containers using:

```bash
docker compose ps
docker compose logs
```

Consider setting up a monitoring solution like Prometheus and Grafana for more comprehensive monitoring.

## Troubleshooting

### Site Not Loading

1. Check if containers are running:
   ```bash
   docker compose ps
   ```

2. Check Caddy logs:
   ```bash
   docker compose logs caddy
   ```

3. Check Ghost logs:
   ```bash
   docker compose logs ghost_mysite
   ```

### Database Connection Issues

1. Check if MySQL is running:
   ```bash
   docker compose logs mysql
   ```

2. Verify database credentials in the site's .env file

3. Connect to MySQL to check databases and users:
   ```bash
   docker exec -it mysql mysql -uroot -p
   ```
   Then run:
   ```sql
   SHOW DATABASES;
   SELECT user,host FROM mysql.user;
   ```

## Customizing Your Setup

### Custom Themes

To use custom themes:

1. Add a volume mount in the site's .yml file:
   ```yaml
   volumes:
     - ghost_content_${SITE_NAME}:/var/lib/ghost/content
     - ./sites/${SITE_DOMAIN}/themes:/var/lib/ghost/content/themes
   ```

2. Place your custom theme in the `sites/mysite.social/themes` directory

### Custom Caddy Configuration

To customize Caddy for specific sites:

1. Edit the Caddyfile
2. Add site-specific configurations

### Performance Tuning

For better performance:

1. Consider adding Redis cache (already included in the setup)
2. Optimize MySQL configuration
3. Add Cloudflare or another CDN in front of your sites

## Advanced Features

### Email Configuration

For proper email delivery:

1. Set up proper mail configuration in each site's .env file
2. Consider using a dedicated mail service like Mailgun, SendGrid, or Amazon SES

### Content API

To use Ghost's Content API for headless CMS functionality:

1. Enable it in the Ghost admin panel
2. Use the API key with your frontend applications

## Security Considerations

1. Use strong passwords for MySQL and Ghost admin
2. Keep all containers updated
3. Consider implementing fail2ban for added security
4. Regularly back up your data
5. Use a firewall to restrict access to necessary ports only
