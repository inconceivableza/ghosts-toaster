#!/bin/bash
# Fallback script to patch source domain names in a Ghost mirror directory.
#
# This script is normally NOT called during static site generation because gssg's
# replaceUrlHelper already replaces all source (ghost.$DOMAIN) references with the
# production domain when --productionDomain is passed.
#
# To enable this script as a post-generation safety net, set ENABLE_POST_PATCH_DOMAINS=1
# in .env. When enabled, it is sourced by generate-static-sites.sh and patch_static_site
# is called after each gssg run to catch any source-domain refs that gssg may have missed.
#
# This script replaces ghost.$DOMAIN (GHOST_PREFIX.$DOMAIN) with $DOMAIN (SITE_DOMAIN),
# matching the same source→production mapping used by gssg's --productionDomain flag.

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

    # Matches https:// http:// "// '// or ref= prefixes followed by the ghost source domain,
    # and replaces with the production domain (SITE_DOMAIN), mirroring gssg --productionDomain.
    GHOST_DOMAIN_SEARCH="${GHOST_PREFIX}${GHOST_PREFIX:+[.]}${SITE_DOMAIN//./[.]}"
    find "$local_output_dir" -type f -exec sed -i 's#\(https://\|http://\|["'"'"']//\|ref=\)'"$GHOST_DOMAIN_SEARCH"'#\1'"$SITE_DOMAIN"'#g' "{}" +
}

# this can be run as an executable script, or sourced so the function can be used
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    patch_static_site "$@"
fi

