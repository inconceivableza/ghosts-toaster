#!/bin/bash
# Script to create a new Ghost site with automatic configuration

# Check for required arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <site_name> <domain_name>"
    echo "Example: $0 myblog myblog.com"
    exit 1
fi

SITE_NAME=$1
SITE_DOMAIN=$2
SITES_DIR="./sites"
SITE_DIR="$SITES_DIR/$SITE_DOMAIN"
GLOBAL_ENV_FILE="./ghosts-toaster.env"

# Make sure the sites directory exists
mkdir -p "$SITES_DIR"

# Check if the site already exists
if [ -d "$SITE_DIR" ]; then
    echo "Error: Site directory $SITE_DIR already exists!"
    exit 1
fi

# Create site directory
mkdir -p "$SITE_DIR"

# Generate a random 24-character password
# Using SHA256 for random data and cutting to 24 characters
DB_PASSWORD=$(head -c 32 /dev/urandom | sha256sum | head -c 24)

# Set database name and user
DB_USER="ghost_${SITE_NAME}"
DB_NAME="ghost_${SITE_NAME}"

# Create the site.env file
cat > "$SITE_DIR/site.env" << EOL
# Site information
SITE_NAME=$SITE_NAME
SITE_DOMAIN=$SITE_DOMAIN

# Database configuration (automatically generated)
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# Static site generation configuration
STATIC_SITE_OUTPUT_DIR=/var/www/static/$SITE_DOMAIN
EOL

echo "Created site configuration at $SITE_DIR/site.env"

# Create an example site.env file for reference
cat > "$SITE_DIR/site.env.example" << EOL
# Site information
SITE_NAME=$SITE_NAME
SITE_DOMAIN=$SITE_DOMAIN

# Database configuration (automatically generated, no need to edit)
DB_USER=$DB_USER
DB_PASSWORD=auto_generated_secure_password
DB_NAME=$DB_NAME

# Static site generation configuration
STATIC_SITE_OUTPUT_DIR=/var/www/static/$SITE_DOMAIN
EOL

echo "Created example configuration at $SITE_DIR/site.env.example"

# Generate the site-specific Docker Compose file
echo "Generating Docker Compose configuration..."
./scripts/generate-site-config.sh

echo "Site $SITE_NAME at $SITE_DOMAIN has been created."
echo "Database user: $DB_USER"
echo "Database name: $DB_NAME"
echo "Database password: $DB_PASSWORD (keep this secure!)"
echo ""
echo "To apply changes and start the site:"
echo "1. Run: docker compose up -d"
echo "2. Wait for the service to initialize"
echo "3. Run: ./scripts/generate-static-sites.sh"
