#!/bin/bash
# Script to generate site-specific Docker Compose files from site.env files

SITES_DIR="./sites"
TEMPLATE_FILE="./site-template.yml"
GLOBAL_ENV_FILE="./ghosts-toaster.env"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Check if global environment file exists, create from example if needed
if [ ! -f "$GLOBAL_ENV_FILE" ] && [ -f "$GLOBAL_ENV_FILE.example" ]; then
    echo "Global environment file not found, creating from example..."
    cp "$GLOBAL_ENV_FILE.example" "$GLOBAL_ENV_FILE"
    echo "Created $GLOBAL_ENV_FILE from example"
fi

# Function to generate site-specific Docker Compose file
generate_site_config() {
    local site_dir=$1
    local site_domain=$(basename "$site_dir")
    local env_file="$site_dir/site.env"
    local output_file="$site_dir/$site_domain.yml"
    
    # Check if site.env file exists
    if [ ! -f "$env_file" ]; then
        echo "Warning: Environment file $env_file not found, skipping..."
        return
    fi
    
    echo "Generating config for $site_domain..."
    
    # Export variables from site.env file and global env file to make them available for envsubst
    set -a
    source "$GLOBAL_ENV_FILE"
    source "$env_file"
    set +a
    
    # Generate the Docker Compose file using template and environment variables
    envsubst < "$TEMPLATE_FILE" > "$output_file"
    
    echo "Generated $output_file"
    
    # Create database if it doesn't exist
    if [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
        echo "Ensuring database $DB_NAME exists with user $DB_USER..."
        # This command should be run when the MySQL container is already running
        docker exec mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
            CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
            CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
            GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
            FLUSH PRIVILEGES;
        " 2>/dev/null || echo "Warning: Could not create database (is MySQL running?)"
    fi
}

# Process all site directories
if [ -d "$SITES_DIR" ]; then
    echo "Processing sites in $SITES_DIR..."
    
    # Find all site.env files in subdirectories of SITES_DIR
    find "$SITES_DIR" -type f -name "site.env" | while read env_file; do
        site_dir=$(dirname "$env_file")
        generate_site_config "$site_dir"
    done
else
    echo "Error: Sites directory $SITES_DIR not found!"
    exit 1
fi

echo "Site configuration generation complete."

# Generate Caddy environment variables for site domains
echo "Generating Caddy environment variables..."
SITES_LIST=""
SITES_NAMES=""

find "$SITES_DIR" -type f -name "site.env" | while read env_file; do
    source "$env_file"
    if [ -n "$SITE_DOMAIN" ]; then
        if [ -z "$SITES_LIST" ]; then
            SITES_LIST="$SITE_DOMAIN"
            SITES_NAMES="$SITE_NAME"
        else
            SITES_LIST="$SITES_LIST,$SITE_DOMAIN"
            SITES_NAMES="$SITES_NAMES,$SITE_NAME"
        fi
    fi
done

# Update global environment file with site list
if [ -n "$SITES_LIST" ]; then
    grep -v "^SITES=" "$GLOBAL_ENV_FILE" > "$GLOBAL_ENV_FILE.tmp" || touch "$GLOBAL_ENV_FILE.tmp"
    grep -v "^SITE_NAMES=" "$GLOBAL_ENV_FILE.tmp" > "$GLOBAL_ENV_FILE.tmp2" || touch "$GLOBAL_ENV_FILE.tmp2"
    mv "$GLOBAL_ENV_FILE.tmp2" "$GLOBAL_ENV_FILE.tmp"
    echo "SITES=$SITES_LIST" >> "$GLOBAL_ENV_FILE.tmp"
    echo "SITE_NAMES=$SITES_NAMES" >> "$GLOBAL_ENV_FILE.tmp"
    mv "$GLOBAL_ENV_FILE.tmp" "$GLOBAL_ENV_FILE"
    echo "Updated $GLOBAL_ENV_FILE with SITES=$SITES_LIST"
fi

echo "Configuration generation complete."
