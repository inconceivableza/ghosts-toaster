#!/bin/bash
# Fallback script to patch source domain names in a Ghost mirror directory.
#
# This script is normally NOT called during static site generation because gssg's
# replaceUrlHelper already replaces all source (ghost.$DOMAIN) references with the
# production domain when --productionDomain is passed.
#
# Re-enable this script (by uncommenting its call in generate-static-sites.sh) if:
#   - gssg's domain replacement stops working (e.g. a regression in replaceUrlHelper)
#   - You need a quick manual fix after a failed generation run
#
# Note: this script replaces ghost.$DOMAIN with toast.$DOMAIN (STATIC_PREFIX.$DOMAIN),
# which differs from gssg's replacement target of $DOMAIN (PRODUCTION_DOMAIN). It is
# therefore only a partial substitute and the gssg --productionDomain flag is preferred.

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

