#!/bin/bash
# Rebuild the static-generator container from local ghosts-toaster-site-generator/ source.
#
# The default build (Dockerfile-static-generator) installs gssg from the published
# GitHub package. Use this script when you have local changes you want to test
# without pushing to GitHub first.
#
# The slow apk/pip/wpull layers are Docker-cached; only the npm install step
# re-runs when source files change, so subsequent rebuilds are fast.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Building static-generator from local source..."
docker compose -f docker-compose.yml -f docker-compose.local.yml build static-generator

echo "Restarting static-generator container..."
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d static-generator

echo "Done. static-generator is running from local source."
