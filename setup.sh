#!/bin/bash
# Main setup script for ghosts-toaster hosting platform

. "`dirname "$0"`"/scripts/utils.sh

# Set up project structure
mkdir -p caddy-sites
mkdir -p sites
mkdir -p static
mkdir -p backups
mkdir -p ssh
chmod go-rwx ssh

# Create global environment file from example if it doesn't exist
if [ ! -f "ghosts-toaster.env" ] && [ -f "ghosts-toaster.env.example" ]; then
    echo "Creating global environment file from example..."
    cp ghosts-toaster.env.example ghosts-toaster.env
    echo "Created ghosts-toaster.env from example"
    
    # Generate a secure random webhook secret
    WEBHOOK_SECRET=$(head -c 32 /dev/urandom | sha256sum | head -c 32)
    sed -i "s/change_this_to_a_secure_random_string/$WEBHOOK_SECRET/" ghosts-toaster.env
    echo "Generated secure webhook secret"
fi

# Load global environment variables to get prefixes
source ghosts-toaster.env

if [ "$SITES" == "" ]
  then
    echo "No sites defined yet. Use ./scripts/create-site.sh to add a site before starting the system" >&2
    exit 1
  fi

echo "Generating site configurations..."
./scripts/generate-site-config.sh

site_containers=""
for SITE_NAME in $SITE_NAMES; do
    site_containers="$site_containers ghost_$SITE_NAME"
done
echo "Starting the system..."
docker compose up -d

echo "Waiting for services to initialize (30 seconds) including $site_containers..."
wait_for_containers 30 mysql redis static-generator caddy webhook-receiver $site_containers

echo "Setup complete! Your ghosts-toaster platform is now running."
echo ""
echo "To add new sites:"
echo "1. Run: ./scripts/create-site.sh <site_name> <domain>"
echo "   Example: ./scripts/create-site.sh myblog myblog.com"
echo "2. Restart the system with 'docker compose up -d'"
echo "3. Follow the instructions to set up the webhook for automatic site updates"
echo "4. Set up the GitHub repository for the static site as instructed"
