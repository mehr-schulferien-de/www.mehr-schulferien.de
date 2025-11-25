#!/bin/bash
#
# This script is used to deploy this application to the production server.

# Lock file mechanism to prevent multiple instances
# Note: GitHub Actions concurrency handles cancellation at workflow level,
# this is a safety fallback in case two scripts somehow run simultaneously
LOCK_FILE="/tmp/mehr-schulferien-deploy.lock"

if [ -f "$LOCK_FILE" ]; then
    echo "Deployment already in progress. Skipping (GitHub Actions should handle this)."
    exit 0
fi

# Create lock file
touch "$LOCK_FILE"

# Ensure lock file is removed when script exits
trap 'rm -f "$LOCK_FILE"; exit' EXIT INT TERM

# Define persistent directories
BUILD_DIR="$HOME/app/build"
RELEASE_DIR="$HOME/app/release"
REPO_DIR="$BUILD_DIR/repo"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Check if we need to update the repository
if [ ! -d "$REPO_DIR" ]; then
    echo "Initial clone of repository..."
    git clone https://github.com/mehr-schulferien-de/www.mehr-schulferien.de.git "$REPO_DIR"
else
    echo "Updating repository..."
    cd "$REPO_DIR" || exit
    git fetch origin master
    git reset --hard origin/master
fi

# Get the version for logging
cd "$REPO_DIR" || exit
new_version=$(grep "version: " mix.exs | sed "s/.*version: \"\(.*\)\",/\1/")
echo "Deploying version: ${new_version}"

# Build the application
cp /home/mehrschul2020/conf/prod.secret.exs "$REPO_DIR/config/prod.secret.exs"
cd "$REPO_DIR" || exit
mix deps.get --only prod
MIX_ENV=prod mix compile

# Build assets using new Phoenix 1.7+ build system
echo "Building assets..."
# Clean old assets first to avoid conflicts
rm -rf priv/static/assets
rm -f priv/static/cache_manifest.json

# Setup assets (Tailwind and ESBuild)
echo "Setting up assets..."
MIX_ENV=prod mix assets.setup

# Build and deploy assets using the proper mix task
echo "Building and deploying assets..."
MIX_ENV=prod mix assets.deploy

# Create non-fingerprinted copies from the fingerprinted versions
# This ensures we always have both versions available
if [ -f "priv/static/cache_manifest.json" ]; then
  echo "Creating non-fingerprinted copies from fingerprinted assets..."

  # Extract the fingerprinted CSS filename from cache manifest
  css_file=$(grep -o '"assets/app-[^"]*\.css"' priv/static/cache_manifest.json | head -1 | tr -d '"')
  if [ -n "$css_file" ] && [ -f "priv/static/$css_file" ]; then
    cp "priv/static/$css_file" "priv/static/assets/app.css"
    echo "Copied $css_file to app.css"
  fi

  # Extract the fingerprinted JS filename from cache manifest
  js_file=$(grep -o '"assets/app-[^"]*\.js"' priv/static/cache_manifest.json | head -1 | tr -d '"')
  if [ -n "$js_file" ] && [ -f "priv/static/$js_file" ]; then
    cp "priv/static/$js_file" "priv/static/assets/app.js"
    echo "Copied $js_file to app.js"
  fi
fi

# Verify assets were built
if [ ! -f "priv/static/cache_manifest.json" ]; then
  echo "ERROR: Assets build failed - cache_manifest.json not found"
  exit 1
fi

# Verify static assets were copied
if [ ! -f "priv/static/images/entschuldigung-vorschau.webp" ]; then
  echo "ERROR: Static assets not copied - entschuldigung-vorschau.webp not found"
  echo "Manually copying static assets..."
  cp -r assets/static/* priv/static/
  if [ ! -f "priv/static/images/entschuldigung-vorschau.webp" ]; then
    echo "ERROR: Failed to copy static assets"
    exit 1
  fi
fi

echo "Assets built successfully, cache manifest and static assets exist"

# Create release
echo "Creating release..."
MIX_ENV=prod mix release --overwrite

# Verify release was created and contains static assets
if [ ! -d "_build/prod/rel/mehr_schulferien" ]; then
  echo "ERROR: Release directory was not created"
  exit 1
fi

if [ ! -f "_build/prod/rel/mehr_schulferien/lib/mehr_schulferien-${new_version}/priv/static/cache_manifest.json" ]; then
  echo "ERROR: Static assets not found in release"
  echo "Checking release structure:"
  find "_build/prod/rel/mehr_schulferien" -name "cache_manifest.json" -o -name "*.css" -o -name "*.js" | head -10
  exit 1
fi

echo "Release created successfully with static assets"

# Stop the server before copying files to avoid "busy" errors
sudo /bin/systemctl stop mehr-schulferien2020.service

# Backup current release if it exists
if [ -d "$RELEASE_DIR" ]; then
  mv "$RELEASE_DIR" "$RELEASE_DIR.backup.$(date +%s)"
fi

# Move new release to final location
mv "_build/prod/rel/mehr_schulferien" "$RELEASE_DIR"

# Verify the moved release has assets
if [ ! -f "$RELEASE_DIR/lib/mehr_schulferien-${new_version}/priv/static/cache_manifest.json" ]; then
  echo "ERROR: Assets not found after moving release"
  exit 1
fi

# Verify static images exist in release
if [ ! -f "$RELEASE_DIR/lib/mehr_schulferien-${new_version}/priv/static/images/entschuldigung-vorschau.webp" ]; then
  echo "ERROR: Static image not found in release"
  exit 1
fi

# Run migrations only if there are pending migrations
"$RELEASE_DIR/bin/mehr_schulferien" eval "MehrSchulferien.ReleaseTasks.migrate"

# Start the server
sudo /bin/systemctl start mehr-schulferien2020.service

# Clean up old backups (keep only the most recent 3)
find "$HOME/app" -name "release.backup.*" -type d | sort | head -n -3 | xargs rm -rf

logger "Deployed release ${new_version} of mehr-schulferien2020."
