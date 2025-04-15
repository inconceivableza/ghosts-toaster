#!/bin/bash
# Main setup script for ghosts-toaster hosting platform

# Set up project structure
echo "Creating directories if they don't exist..."
mkdir -p sites
mkdir -p static
mkdir -p backups
mkdir -p webhook

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

# Create example site if it doesn't exist
if [ ! -d "sites/mysite.social" ]; then
    echo "Setting up example site..."
    ./scripts/create-site.sh mysite mysite.social
    echo "Created example site"
fi

echo "Generating site configurations..."
./scripts/generate-site-config.sh

echo "Starting the system..."
docker compose up -d

echo "Waiting for services to initialize (30 seconds)..."
sleep 30

echo "Generating static sites..."
./scripts/generate-static-sites.sh

echo "Setup complete! Your ghosts-toaster platform is now running."
echo "You can access your Ghost admin at: https://ghost.mysite.social/ghost/"
echo "The public site is available at: https://mysite.social"
echo ""
echo "To add new sites:"
echo "1. Run: ./scripts/create-site.sh <site_name> <domain>"
echo "   Example: ./scripts/create-site.sh myblog myblog.com"
echo "2. Restart the system with 'docker compose up -d'"
echo "3. Follow the instructions to set up the webhook for automatic site updates"
