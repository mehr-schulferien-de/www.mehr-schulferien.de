#!/bin/bash
#
# This script is used to deploy this application to the production server.

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
    git fetch origin
    git reset --hard origin/main
fi

# Get the new version
cd "$REPO_DIR" || exit
new_version=`grep "version: " mix.exs | sed "s/.*version: \"\(.*\)\",/\1/"`

### Check if a new version directory does not exist ###
if [ ! -d "$RELEASE_DIR/releases/${new_version}" ] 
then
  echo "New version: ${new_version}"

  # Build the application
  cp /home/mehrschul2020/conf/prod.secret.exs "$REPO_DIR/config/prod.secret.exs"
  cd "$REPO_DIR" || exit
  mix deps.get --only prod
  MIX_ENV=prod mix compile

  # Build assets using new Phoenix 1.7+ build system
  echo "Building assets..."
  MIX_ENV=prod mix assets.setup
  MIX_ENV=prod mix assets.deploy

  # Verify assets were built
  if [ ! -f "priv/static/cache_manifest.json" ]; then
    echo "ERROR: Assets build failed - cache_manifest.json not found"
    exit 1
  fi
  
  echo "Assets built successfully, cache manifest exists"
  echo "Asset files found:"
  ls -la priv/static/assets/ | head -10

  # Create release
  echo "Creating release..."
  MIX_ENV=prod mix release --overwrite --path "$RELEASE_DIR"

  # Verify release was created and contains static assets
  if [ ! -d "$RELEASE_DIR" ]; then
    echo "ERROR: Release directory was not created"
    exit 1
  fi
  
  if [ ! -f "$RELEASE_DIR/lib/mehr_schulferien-${new_version}/priv/static/cache_manifest.json" ]; then
    echo "ERROR: Static assets not found in release"
    echo "Checking release structure:"
    find "$RELEASE_DIR" -name "cache_manifest.json" -o -name "*.css" -o -name "*.js" | head -10
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
  mv "$REPO_DIR/release" "$RELEASE_DIR"

  # Verify the moved release has assets
  if [ ! -f "$RELEASE_DIR/lib/mehr_schulferien-${new_version}/priv/static/cache_manifest.json" ]; then
    echo "ERROR: Assets not found after moving release"
    exit 1
  fi

  # Run migrations only if there are pending migrations
  "$RELEASE_DIR/bin/mehr_schulferien" eval "MehrSchulferien.ReleaseTasks.migrate"

  # Start the server
  sudo /bin/systemctl start mehr-schulferien2020.service

  # Clean up old backups (keep only the most recent 3)
  find "$HOME/app" -name "release.backup.*" -type d | sort | head -n -3 | xargs rm -rf

  logger "Deployed release ${new_version} of mehr-schulferien2020."
else
  echo "Version ${new_version} already deployed, nothing to do."
fi
