#!/bin/bash
# Script to generate static versions of Ghost sites

SITES_DIR="./sites"
STATIC_DIR="./static"
GLOBAL_ENV_FILE="./ghosts-toaster.env"

# Load global environment variables
if [ -f "$GLOBAL_ENV_FILE" ]; then
    source "$GLOBAL_ENV_FILE"
fi

# Make sure the static directory exists
mkdir -p "$STATIC_DIR"

# Function to generate static site for a Ghost instance
generate_static_site() {
    local site_dir=$1
    local env_file="$site_dir/site.env"
    
    # Check if site.env file exists
    if [ ! -f "$env_file" ]; then
        echo "Warning: Environment file $env_file not found, skipping..."
        return
    fi
    
    # Load environment variables
    set -a
    source "$env_file"
    set +a
    
    local site_domain="$SITE_DOMAIN"
    local site_name="$SITE_NAME"
    local output_dir="${STATIC_SITE_OUTPUT_DIR:-$STATIC_DIR/$site_domain}"
    
    echo "Generating static site for $site_domain..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Use docker exec to run the static site generator in the container
    docker exec static-generator gssg --url "http://ghost_${site_name}:2368" --dest "/output/$site_domain"
    
    echo "Static site for $site_domain generated in $output_dir"
    
    # Update Git repository for the static site
    if [ -d "$output_dir" ]; then
        echo "Updating Git repository for $site_domain..."
        ./scripts/update-git-repository.sh "$site_domain"
    fi
}

# Process all site directories
if [ -d "$SITES_DIR" ]; then
    echo "Processing sites in $SITES_DIR..."
    
    # Find all site.env files in subdirectories of SITES_DIR
    find "$SITES_DIR" -type f -name "site.env" | while read env_file; do
        site_dir=$(dirname "$env_file")
        generate_static_site "$site_dir"
    done
else
    echo "Error: Sites directory $SITES_DIR not found!"
    exit 1
fi

echo "Static site generation complete."

# Set appropriate permissions for the static directory
chmod -R 755 "$STATIC_DIR"
