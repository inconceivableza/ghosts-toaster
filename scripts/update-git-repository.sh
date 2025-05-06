#!/bin/bash
# Script to update a Git repository for a static site

# Check if site domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <site_domain>"
    exit 1
fi

SITE_DOMAIN="$1"
STATIC_DIR="../static"
SITE_DIR="$STATIC_DIR/$SITE_DOMAIN"

if [ ! -d "$SITE_DIR" ]; then
    echo "Error: Static site directory $SITE_DIR does not exist!"
    exit 1
fi

echo "Updating Git repository for $SITE_DOMAIN..."

# Change to the static site directory
cd "$SITE_DIR" || exit 1

# Initialize Git repository if it doesn't exist
if [ ! -d ".git" ]; then
    echo "Initializing new Git repository in $SITE_DIR"
    git init
    
    # Create basic .gitignore file
    cat > ".gitignore" << EOL
# Ghost static generator specific
.DS_Store
*.log
node_modules/
EOL

    echo "Git repository initialized. Please set up the remote with:"
    echo "  cd $SITE_DIR"
    echo "  git remote add origin git@github.com:yourusername/$SITE_DOMAIN.git"
    echo "  git branch -M main"
    echo "Please also add the following ssh key as a deploy key for this repository, with write permissions:"
    cat /root/.ssh/id_ed25519.pub
    echo "This can be done at https://github.com/yourusername/$SITE_DOMAIN/settings/keys
    
    # Perform initial commit
    git add --all .
    git commit -m "Initial commit - $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "Git repository already exists in $SITE_DIR"
    
    # Add all changes, commit and push
    git add --all .
    
    # Commit changes if there are any
    if git status --porcelain | grep -q .; then
        git commit -m "Update static site - $(date '+%Y-%m-%d %H:%M:%S')"
        
        # Check if remote exists before pushing
        if git remote -v | grep -q origin; then
            echo "Pushing changes to remote repository..."
            if git push origin HEAD; then
                echo "Successfully pushed changes to origin"
            else
                echo "Warning: Could not push to remote. Please check your git configuration."
            fi
        else
            echo "Remote 'origin' not found. You can add it with:"
            echo "  cd $SITE_DIR"
            echo "  git remote add origin https://github.com/yourusername/$SITE_DOMAIN.git"
            echo "  git branch -M main"
        fi
    else
        echo "No changes to commit for $SITE_DOMAIN"
    fi
fi

echo "Git repository update completed for $SITE_DOMAIN"
