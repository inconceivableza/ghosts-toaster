#!/bin/bash
# Script to generate static versions of Ghost sites

script_dir="$(cd "$(dirname "$0")"; pwd)"
root_dir="$(cd "$(dirname "$script_dir")"; pwd)"

SITES_DIR="$root_dir/sites"
STATIC_DIR="$root_dir/static"
SG_STATIC_DIR="/static"
GLOBAL_ENV_FILE="$root_dir/.env"

# Load global environment variables
if [ -f "$GLOBAL_ENV_FILE" ]; then
    source "$GLOBAL_ENV_FILE"
fi

# patch-domains.sh is kept as a fallback in case gssg fails to replace source domain references
# Uncomment if gssg domain replacement breaks to quickly restore static data, until gssg can be fixed.
# . $script_dir/patch-domains.sh

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
    local local_output_dir="$STATIC_DIR/$site_domain"
    local sg_output_dir="$SG_STATIC_DIR/$site_domain"
    
    echo "Generating static site for $site_domain..."
    
    # Create output directory if it doesn't exist
    echo "Creating $sg_output_dir"
    docker exec -u "${STATIC_USER:=appuser}" static-generator mkdir -p "$sg_output_dir"
    
    # Use docker exec to run the static site generator in the container
    echo "Running gssg"
    GHOST_DOMAIN=${GHOST_PREFIX}${GHOST_PREFIX:+.}$SITE_DOMAIN
    docker exec -u "${STATIC_USER:=appuser}" static-generator gssg --domain "https://$GHOST_DOMAIN" --productionDomain "https://$SITE_DOMAIN" --dest "$sg_output_dir" --avoid-https
    
    echo "Static site for $site_domain generated in $local_output_dir"
    # patch_static_site is a fallback for gssg domain replacement failures - see comment above.
    # patch_static_site "$site_domain"

    # Update Git repository for the static site
    if [ -d "$local_output_dir" ]; then
        echo "Using static-generator container to update Git repository for $site_domain..."
        docker exec -t -u "${STATIC_USER:=appuser}" static-generator /scripts/update-git-repository.sh "$site_domain"
        echo done
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
