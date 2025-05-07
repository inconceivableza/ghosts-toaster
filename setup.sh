#!/bin/bash
# Main setup script for ghosts-toaster hosting platform

. "`dirname "$0"`"/scripts/utils.sh

cd "`dirname "$0"`"

# Set up project structure
mkdir -p caddy-sites
mkdir -p sites
mkdir -p static
mkdir -p backups
mkdir -p ssh
chmod go-rwx ssh

# Create global environment file from example if it doesn't exist
if [ ! -f ".env" ] && [ -f "ghosts-toaster.env.example" ]; then
    echo "Creating global environment file from example..."
    cp ghosts-toaster.env.example .env
    echo "Created .env from example"
    echo "Please populate this following the README before continuing with setup" >&2
    exit 1
fi

if grep very_secure_root_password .env > /dev/null || grep change_this_to_a_secure_random_string .env > /dev/null; then
    echo Will generate a secure random webhook secret and/or mysql root password
    MYSQL_ROOT_PASSWORD=$(head -c 32 /dev/urandom | sha256sum | head -c 32)
    sed -i "s/very_secure_root_password/$MYSQL_ROOT_PASSWORD/" .env
    grep $MYSQL_ROOT_PASSWORD .env > /dev/null && echo "Generated secure mysql root password"
    WEBHOOK_SECRET=$(head -c 32 /dev/urandom | sha256sum | head -c 32)
    sed -i "s/change_this_to_a_secure_random_string/$WEBHOOK_SECRET/" .env
    grep $WEBHOOK_SECRET .env > /dev/null && echo "Generated secure webhook secret"
    echo Password generation complete
fi

# Load global environment variables to get prefixes
source .env

echo Starting up universal services
docker compose create
docker compose up -d `docker container ls --all --filter label=group=universal --format '{{.Names}}'`
wait_for_container mysql

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
