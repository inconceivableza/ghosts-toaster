#!/bin/bash

# Function to generate static site for a Ghost instance
patch_static_site() {
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
    
    echo "Patching static site for $site_domain..."

    # this should support https:// http:// "// '// or ref= as prefixes that if matched with the domain name should be adjusted
    find "$local_output_dir" -type f -exec sed -i 's#\(https://\|http://\|["'"'"']//\|ref=\)ghost[.]'"$SITE_DOMAIN"'#\1toast.'"$SITE_DOMAIN#g" "{}" +
}

# this can be run as an executable script, or sourced so the function can be used
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    patch_static_site "$@"
fi

