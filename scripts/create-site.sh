#!/bin/bash
# Script to create a new Ghost site with automatic configuration

# Check for required arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <site_name> <domain_name>"
    echo "Example: $0 myblog myblog.com"
    exit 1
fi

export SITE_NAME=$1
export SITE_DOMAIN=$2
SITES_DIR="./sites"
SITE_DIR="$SITES_DIR/$SITE_DOMAIN"
STATIC_DIR="./static/$SITE_DOMAIN"
GLOBAL_ENV_FILE="./.env"
ENV_TEMPLATE_FILE="./site-template.env"

# Load global environment variables to get prefixes
if [ -f "$GLOBAL_ENV_FILE" ]; then
    source "$GLOBAL_ENV_FILE"
fi

# Set default prefixes if not defined
GHOST_PREFIX=${GHOST_PREFIX:-ghost}
STATIC_PREFIX=${STATIC_PREFIX:-www}

# Make sure the sites directory exists
mkdir -p "$SITES_DIR"

# Check if the site already exists
if [ -d "$SITE_DIR" ]; then
    echo "Error: Site directory $SITE_DIR already exists!" >&2
    echo
    echo Information for site $SITE_NAME at $SITE_DOMAIN follows:
else
    # Create site directory
    mkdir -p "$SITE_DIR"

    # Generate a random 24-character password
    # Using SHA256 for random data and cutting to 24 characters
    export DB_PASSWORD=$(head -c 32 /dev/urandom | sha256sum | head -c 24)

    # Set database name and user
    export DB_USER="ghost_${SITE_NAME}"
    export DB_NAME="ghost_${SITE_NAME}"

    # Create the site.env file
    envsubst < "$ENV_TEMPLATE_FILE" '$SITE_NAME $SITE_DOMAIN $DB_NAME $DB_USER $DB_PASSWORD' | grep -v '# This is a template' > "$SITE_DIR/site.env"
    echo "Created site configuration at $SITE_DIR/site.env"

    # Generate the site-specific Docker Compose file
    echo "Generating Docker Compose configuration and setting up database..."
    ./scripts/generate-site-config.sh

    echo "Site $SITE_NAME at $SITE_DOMAIN has been created."
echo "Database user: $DB_USER"
echo "Database name: $DB_NAME"
echo "Database password: $DB_PASSWORD (keep this secure!)"
fi

echo ""
echo "To apply changes and start the site:"
echo "1. Run: docker compose up -d"
echo "2. Wait for the service to initialize"
echo "3. Your static site will be generated automatically"
echo ""

# Get the webhook secret from the global environment file
WEBHOOK_SECRET=$(grep WEBHOOK_SECRET $GLOBAL_ENV_FILE | cut -d= -f2)
if [ -z "$WEBHOOK_SECRET" ]; then
    echo "ERROR: No webhook secret found in $GLOBAL_ENV_FILE!." >&2
    echo "Please update the WEBHOOK_SECRET in $GLOBAL_ENV_FILE for security." >&2
    exit 1
fi

echo "===== Setting up webhook for automatic static site generation ====="
echo "After your Ghost site is running, set up the webhook with these steps:"
echo ""
echo "1. Access your Ghost admin panel at https://$GHOST_PREFIX.$SITE_DOMAIN/ghost/"
echo "2. Go to Settings > Integrations"
echo "3. Click 'Add custom integration'"
echo "4. Name it 'Static Site Generator'"
echo "5. Click 'Create'"
echo "6. In the integration details, scroll down to 'Webhooks'"
echo "7. Add a webhook with the following details:"
echo "   - Name: 'Site Changed'"
echo "   - Event: 'site.changed'"
echo "   - Target URL: 'http://webhook-receiver.docker.internal:9000/webhook/$SITE_NAME'"
echo "   - Secret: '$WEBHOOK_SECRET'"
echo ""
echo "This webhook will automatically trigger the static site generation"
echo "whenever content is published, updated, or deleted on your Ghost site."
echo ""
echo "===== Setting up Git repository for the static site ====="
echo "A Git repository will be automatically initialized in $STATIC_DIR"
echo "After the static site is generated, set up the remote repository with these steps:"
echo ""
echo "1. Create a new repository on GitHub named '$SITE_DOMAIN'"
echo "2. Run the following commands to configure the remote from the static generator container:"
echo "   docker compose exec static-generator bash /scripts/update-git-repository.sh $SITE_DOMAIN"
echo ""
echo "After this setup, all static site updates will be automatically committed and pushed to GitHub."
echo ""
echo "===== Access Your New Site ====="
echo "Once setup is complete, your site will be available at:"
echo "- Ghost Admin: https://$GHOST_PREFIX.$SITE_DOMAIN/ghost/"
echo "- Static Site: https://$STATIC_PREFIX.$SITE_DOMAIN"
echo "- Main Domain: https://$SITE_DOMAIN"
