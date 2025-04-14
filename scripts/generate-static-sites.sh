#!/bin/bash
# Script to generate static versions of Ghost sites

SITES_DIR="./sites"
STATIC_DIR="./static"
GSSG_IMAGE="docker.io/adryd325/docker-ghost-static-site-generator:${GSSG_VERSION:-latest}"

# Make sure the static directory exists
mkdir -p "$STATIC_DIR"

# Function to generate static site for a Ghost instance
generate_static_site() {
    local site_dir=$1
    local env_file="$site_dir/.env"
    
    # Check if .env file exists
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
    
    # Run ghost-static-site-generator in a Docker container
    # We connect to the Ghost container directly using the container name
    docker run --rm \
        --network="multi-ghost-server_ghost_network" \
        -v "$output_dir:/output" \
        "$GSSG_IMAGE" \
        --url "http://ghost_${site_name}:2368" \
        --dest "/output"
    
    echo "Static site for $site_domain generated in $output_dir"
}

# Process all site directories
if [ -d "$SITES_DIR" ]; then
    echo "Processing sites in $SITES_DIR..."
    
    # Find all .env files in subdirectories of SITES_DIR
    find "$SITES_DIR" -type f -name ".env" | while read env_file; do
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
