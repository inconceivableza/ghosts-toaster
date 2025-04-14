#!/bin/bash
# Script to generate site-specific Docker Compose files from .env files

SITES_DIR="./sites"
TEMPLATE_FILE="./site-template.yml"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Function to generate site-specific Docker Compose file
generate_site_config() {
    local site_dir=$1
    local site_domain=$(basename "$site_dir")
    local env_file="$site_dir/.env"
    local output_file="$site_dir/$site_domain.yml"
    
    # Check if .env file exists
    if [ ! -f "$env_file" ]; then
        echo "Warning: Environment file $env_file not found, skipping..."
        return
    fi
    
    echo "Generating config for $site_domain..."
    
    # Export variables from .env file to make them available for envsubst
    set -a
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

# Generate a template file if it doesn't exist
if [ ! -f "$TEMPLATE_FILE" ]; then
    cat > "$TEMPLATE_FILE" << EOL
$(cat ./site-template.yml)
EOL
    echo "Created template file: $TEMPLATE_FILE"
fi

# Process all site directories
if [ -d "$SITES_DIR" ]; then
    echo "Processing sites in $SITES_DIR..."
    
    # Find all .env files in subdirectories of SITES_DIR
    find "$SITES_DIR" -type f -name ".env" | while read env_file; do
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

find "$SITES_DIR" -type f -name ".env" | while read env_file; do
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

# Update global .env file with site list
if [ -n "$SITES_LIST" ]; then
    grep -v "^SITES=" ./.env > ./.env.tmp || touch ./.env.tmp
    echo "SITES=$SITES_LIST" >> ./.env.tmp
    echo "SITE_NAMES=$SITES_NAMES" >> ./.env.tmp
    mv ./.env.tmp ./.env
    echo "Updated .env with SITES=$SITES_LIST"
fi

echo "Configuration generation complete."
