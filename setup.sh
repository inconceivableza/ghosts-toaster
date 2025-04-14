#!/bin/bash
# Main setup script for multi-Ghost hosting platform

# Set up project structure
echo "Creating project structure..."
mkdir -p sites
mkdir -p static
mkdir -p scripts

# Copy template files to their appropriate locations
echo "Copying template files..."

# Copy site template file
cat > site-template.yml << 'EOL'
$(cat ./site-template.yml)
EOL

# Copy scripts
cat > scripts/generate-site-config.sh << 'EOL'
$(cat ./scripts/generate-site-config.sh)
EOL

cat > scripts/generate-static-sites.sh << 'EOL'
$(cat ./scripts/generate-static-sites.sh)
EOL

# Make scripts executable
chmod +x scripts/generate-site-config.sh
chmod +x scripts/generate-static-sites.sh

echo "Setting up example site..."
mkdir -p sites/mysite.social
cat > sites/mysite.social/.env << 'EOL'
$(cat ./sites/mysite.social/.env)
EOL

echo "Initial setup complete. Now generating site configurations..."
./scripts/generate-site-config.sh

echo "Starting the system..."
docker compose up -d

echo "Waiting for services to initialize (30 seconds)..."
sleep 30

echo "Generating static sites..."
./scripts/generate-static-sites.sh

echo "Setup complete! Your multi-Ghost platform is now running."
echo "You can access your Ghost admin at: https://ghost.mysite.social/ghost/"
echo "The public site is available at: https://mysite.social"
echo ""
echo "To add new sites:"
echo "1. Create a new directory under 'sites/' with the domain name"
echo "2. Create a .env file in that directory (use mysite.social as a template)"
echo "3. Run ./scripts/generate-site-config.sh to generate the site configuration"
echo "4. Restart the system with 'docker compose up -d'"
echo "5. Run ./scripts/generate-static-sites.sh to generate the static site"
