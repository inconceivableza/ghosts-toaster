#!/bin/bash
# Main setup script for ghosts-toaster hosting platform

# Set up project structure
echo "Creating directories if they don't exist..."
mkdir -p sites
mkdir -p static

# Make scripts executable
chmod +x scripts/generate-site-config.sh
chmod +x scripts/generate-static-sites.sh

# Create global environment file from example if it doesn't exist
if [ ! -f "ghosts-toaster.env" ] && [ -f "ghosts-toaster.env.example" ]; then
    echo "Creating global environment file from example..."
    cp ghosts-toaster.env.example ghosts-toaster.env
    echo "Created ghosts-toaster.env from example"
fi

# Create example site if it doesn't exist
if [ ! -d "sites/mysite.social" ]; then
    echo "Setting up example site..."
    mkdir -p sites/mysite.social
    if [ -f "sites/mysite.social/site.env.example" ]; then
        cp sites/mysite.social/site.env.example sites/mysite.social/site.env
        echo "Created site.env for example site"
    fi
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
echo "1. Create a new directory under 'sites/' with the domain name"
echo "2. Create a site.env file in that directory from site.env.example"
echo "3. Run ./scripts/generate-site-config.sh to generate the site configuration"
echo "4. Restart the system with 'docker compose up -d'"
echo "5. Run ./scripts/generate-static-sites.sh to generate the static site"
