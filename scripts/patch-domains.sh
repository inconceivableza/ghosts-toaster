#!/bin/bash
# Script patch domain names for a Ghost mirror directory

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

# Function to patch domain names for a Ghost mirror directory
patch_static_site() {
    local site_domain=$1
    local env_file="$SITES_DIR/$site_domain/site.env"
    
    # Check if site.env file exists
    if [ ! -f "$env_file" ]; then
        echo "Warning: Environment file $env_file not found, skipping..."
        return
    fi
    
    # Load environment variables
    set -a
    source "$env_file"
    set +a
    
    local local_output_dir="$STATIC_DIR/$SITE_DOMAIN"
    
    echo "Patching static site for $SITE_DOMAIN..."

    # this should support https:// http:// "// '// or ref= as prefixes that if matched with the domain name should be adjusted
    GHOST_DOMAIN_SEARCH="${GHOST_PREFIX}${GHOST_PREFIX:+[.]}${SITE_DOMAIN//./[.]}"
    STATIC_DOMAIN_REPLACE="${STATIC_PREFIX}${STATIC_PREFIX:+.}${SITE_DOMAIN}"
    find "$local_output_dir" -type f -exec sed -i 's#\(https://\|http://\|["'"'"']//\|ref=\)'"$GHOST_DOMAIN_SEARCH"'#\1'"$STATIC_DOMAIN_REPLACE#g" "{}" +
}

# this can be run as an executable script, or sourced so the function can be used
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    patch_static_site "$@"
fi

