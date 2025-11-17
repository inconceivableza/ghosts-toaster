#!/bin/bash
# Script to update a Git repository for a static site

# Check if site domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <site_domain>"
    exit 1
fi

SITE_DOMAIN="$1"
STATIC_DIR="/static"
SITE_DIR="$STATIC_DIR/$SITE_DOMAIN"

if [ ! -d "$SITE_DIR" ]; then
    echo "Error: Static site directory $SITE_DIR does not exist!"
    exit 1
fi

echo "Updating Git repository for $SITE_DOMAIN..."

# Change to the static site directory
cd "$SITE_DIR" || exit 1

function check_setup_git_ssh() {
    ssh_key_file=~/.ssh/id_ed25519-$GIT_REPO_PREFIX$SITE_DOMAIN
    [[ -f $ssh_key_file.pub ]] || {
        echo "Generating new ssh key for $SITE_DOMAIN..."
        ssh-keygen -t ed25519 -f $ssh_key_file -N ''
    }
    grep "github.com-$GIT_REPO_PREFIX$SITE_DOMAIN" ~/.ssh/config > /dev/null 2>&1 || {
        echo "Adjusting ssh config for git for $SITE_DOMAIN..."
        (
            echo "Host github.com-$GIT_REPO_PREFIX$SITE_DOMAIN"
            echo "    Hostname github.com"
            echo "    IdentityFile=$ssh_key_file"
            echo ""
        ) >> ~/.ssh/config
    }
    git remote -v | grep -q origin || {
        echo "Setting up git remote for $SITE_DOMAIN..."
        git remote add origin git@github.com-$GIT_REPO_PREFIX$SITE_DOMAIN:$GIT_OWNER_ID/$GIT_REPO_PREFIX$SITE_DOMAIN.git
        git push -u origin main || show_git_instructions
    }
}

function show_git_instructions() {
    echo "Please add the following ssh key as a deploy key for this repository, with write permissions:"
    echo

    cat $ssh_key_file.pub
    echo
    echo "This can be done at https://github.com/$GIT_OWNER_ID/$GIT_REPO_PREFIX$SITE_DOMAIN/settings/keys"
    echo
    echo "Then please complete pushing to the remote, using docker compose exec static-generator bash:"
    echo "  cd $SITE_DIR"
    echo "  git push -u origin main"
    echo "This may ask you to confirm the remote github key"
}

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

    # Perform initial commit
    git add --all .
    git commit -m "Initial commit - $(date '+%Y-%m-%d %H:%M:%S')"

    echo "Git repository initialized."
    check_setup_git_ssh
    show_git_instructions
else
    echo "Git repository already exists in $SITE_DIR"
    check_setup_git_ssh

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
            echo "Remote 'origin' not found. Follow these instructions to set up git remote:"
            show_git_instructions
        fi
    else
        echo "No changes to commit for $SITE_DOMAIN"
    fi
fi

echo "Git repository update completed for $SITE_DOMAIN"
