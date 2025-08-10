#!/usr/bin/env bash

set -e

# Git shell command to create a new git bare repository
# This script is copied as 'create-repo' in git-shell-commands
# Usage: create-repo <repository-name>

if [ $# -ne 1 ]; then
    echo "Usage: create-repo <repository-name>"
    echo "Example: create-repo my-project"
    echo "This will create my-project.git in /srv/git-repos/"
    exit 1
fi

REPO_NAME="$1"
REPO_DIR="/srv/git-repos/${REPO_NAME}.git"

# Check if repository already exists
if [ -d "$REPO_DIR" ]; then
    echo "Error: Repository '$REPO_NAME.git' already exists at $REPO_DIR"
    exit 1
fi

echo "Creating bare git repository: $REPO_NAME.git"

# Create and initialize the bare repository
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init --bare --shared=group

echo "Repository created successfully!"
echo ""
echo "To clone this repository:"
echo "  git clone gituser@git:/srv/git-repos/${REPO_NAME}.git"
echo ""
echo "To add as remote to existing repository:"
echo "  git remote add origin gituser@git:/srv/git-repos/${REPO_NAME}.git"
echo "  git push -u origin main"
echo ""
echo "Repository location: $REPO_DIR"
