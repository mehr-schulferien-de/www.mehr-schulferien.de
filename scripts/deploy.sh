#!/bin/bash
#
# This script is used to deploy this application to the production server.
# Supports both hot code upgrades (<1s, zero downtime) and cold deploys.
#
# Hot deploy is used when:
# - No database migrations are pending
# - No [cold-deploy] or [restart] tag in commit message
# - Application is currently running
#
# Cold deploy is used when:
# - Database migrations are pending
# - Commit message contains [cold-deploy], [restart], or [supervision]
# - Application is not running
# - Hot deploy fails

set -e

# Lock file mechanism to prevent multiple instances
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
HOT_UPGRADES_DIR="$HOME/app/hot-upgrades"
ENV_FILE="$HOME/conf/env"

# Create directories if they don't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$HOT_UPGRADES_DIR"

# Source environment variables (DATABASE_URL, SECRET_KEY_BASE, etc.)
if [ -f "$ENV_FILE" ]; then
    echo "Sourcing environment from $ENV_FILE"
    set -a  # automatically export all variables
    source "$ENV_FILE"
    set +a
else
    echo "ERROR: Environment file not found at $ENV_FILE"
    exit 1
fi

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

# Get the version and commit info for logging
cd "$REPO_DIR" || exit
new_version=$(grep "version: " mix.exs | sed "s/.*version: \"\(.*\)\",/\1/")
commit_msg=$(git log -1 --pretty=%B)
commit_hash=$(git rev-parse --short HEAD)

echo "Deploying version: ${new_version} (${commit_hash})"

# Function to check if cold deploy is required
requires_cold_deploy() {
    # Check commit message for cold deploy tags
    if echo "$commit_msg" | grep -qiE '\[(cold-deploy|restart|supervision)\]'; then
        echo "Cold deploy requested via commit message"
        return 0
    fi

    # Check if application is running
    if ! systemctl is-active --quiet mehr-schulferien2025.service 2>/dev/null; then
        echo "Application not running - cold deploy required"
        return 0
    fi

    # Check for pending migrations
    cd "$REPO_DIR" || exit

    # Get list of migration files
    local_migrations=$(ls -1 priv/repo/migrations/*.exs 2>/dev/null | wc -l)

    if [ "$local_migrations" -gt 0 ]; then
        # Check if there are unapplied migrations by comparing with database
        # This requires the release to be available to run eval
        if [ -d "$RELEASE_DIR" ] && [ -f "$RELEASE_DIR/bin/mehr_schulferien" ]; then
            pending=$("$RELEASE_DIR/bin/mehr_schulferien" eval "
                migrations = Ecto.Migrator.migrations(MehrSchulferien.Repo)
                pending = Enum.filter(migrations, fn {status, _, _} -> status == :down end)
                IO.puts(length(pending))
            " 2>/dev/null || echo "0")

            if [ "$pending" != "0" ] && [ -n "$pending" ]; then
                echo "Pending migrations detected - cold deploy required"
                return 0
            fi
        fi
    fi

    return 1
}

# Function to perform hot deploy
do_hot_deploy() {
    echo "==> Attempting hot code upgrade..."

    # Build the application
    cp /home/mehrschul2025/conf/prod.secret.exs "$REPO_DIR/config/prod.secret.exs"
    cd "$REPO_DIR" || exit
    mix deps.get --only prod
    MIX_ENV=prod mix compile

    # Build assets
    echo "Building assets..."
    rm -rf priv/static/assets
    rm -f priv/static/cache_manifest.json
    MIX_ENV=prod mix assets.setup
    MIX_ENV=prod mix assets.deploy

    # Create non-fingerprinted copies
    if [ -f "priv/static/cache_manifest.json" ]; then
        echo "Creating non-fingerprinted copies..."
        css_file=$(grep -o '"assets/app-[^"]*\.css"' priv/static/cache_manifest.json | head -1 | tr -d '"')
        if [ -n "$css_file" ] && [ -f "priv/static/$css_file" ]; then
            cp "priv/static/$css_file" "priv/static/assets/app.css"
        fi
        js_file=$(grep -o '"assets/app-[^"]*\.js"' priv/static/cache_manifest.json | head -1 | tr -d '"')
        if [ -n "$js_file" ] && [ -f "priv/static/$js_file" ]; then
            cp "priv/static/$js_file" "priv/static/assets/app.js"
        fi
    fi

    # Prepare hot upgrade package
    echo "Preparing hot upgrade package..."
    upgrade_version="${new_version}-${commit_hash}"
    upgrade_dir="$HOT_UPGRADES_DIR/$upgrade_version"
    beams_dir="$upgrade_dir/beams"

    mkdir -p "$beams_dir"

    # Copy all compiled beam files
    find "_build/prod/lib/mehr_schulferien/ebin" -name "*.beam" -exec cp {} "$beams_dir/" \;
    find "_build/prod/lib/mehr_schulferien_web/ebin" -name "*.beam" -exec cp {} "$beams_dir/" \; 2>/dev/null || true

    beam_count=$(ls -1 "$beams_dir"/*.beam 2>/dev/null | wc -l)
    echo "Prepared $beam_count beam files for hot upgrade"

    if [ "$beam_count" -eq 0 ]; then
        echo "No beam files found - falling back to cold deploy"
        return 1
    fi

    # Write pending marker to trigger hot upgrade
    echo "$upgrade_version" > "$HOT_UPGRADES_DIR/pending"

    # Trigger hot upgrade via the running application
    echo "Triggering hot code upgrade..."
    result=$("$RELEASE_DIR/bin/mehr_schulferien" eval "
        case MehrSchulferien.HotDeploy.check_and_apply() do
            {:ok, :upgraded, version} -> IO.puts(\"HOT_UPGRADE_SUCCESS:\#{version}\")
            {:ok, :no_upgrade} -> IO.puts(\"HOT_UPGRADE_NO_PENDING\")
            {:ok, :disabled} -> IO.puts(\"HOT_UPGRADE_DISABLED\")
            {:error, reason} -> IO.puts(\"HOT_UPGRADE_FAILED:\#{inspect(reason)}\")
        end
    " 2>&1)

    echo "Hot upgrade result: $result"

    if echo "$result" | grep -q "HOT_UPGRADE_SUCCESS"; then
        echo "✅ Hot code upgrade successful!"

        # Update static assets in running release
        echo "Updating static assets..."
        release_static="$RELEASE_DIR/lib/mehr_schulferien-${new_version}/priv/static"
        if [ -d "$release_static" ]; then
            cp -r priv/static/* "$release_static/"
        fi

        # Clean up old hot upgrade directories (keep last 5)
        cd "$HOT_UPGRADES_DIR"
        ls -dt */ 2>/dev/null | tail -n +6 | xargs -r rm -rf

        logger "Hot deployed release ${new_version} (${commit_hash}) of mehr-schulferien2025."
        return 0
    else
        echo "Hot upgrade failed - falling back to cold deploy"
        rm -f "$HOT_UPGRADES_DIR/pending"
        return 1
    fi
}

# Function to perform cold deploy
do_cold_deploy() {
    echo "==> Performing cold deploy..."

    # Build the application
    cp /home/mehrschul2025/conf/prod.secret.exs "$REPO_DIR/config/prod.secret.exs"
    cd "$REPO_DIR" || exit
    mix deps.get --only prod
    MIX_ENV=prod mix compile

    # Build assets
    echo "Building assets..."
    rm -rf priv/static/assets
    rm -f priv/static/cache_manifest.json

    echo "Setting up assets..."
    MIX_ENV=prod mix assets.setup

    echo "Building and deploying assets..."
    MIX_ENV=prod mix assets.deploy

    # Create non-fingerprinted copies
    if [ -f "priv/static/cache_manifest.json" ]; then
        echo "Creating non-fingerprinted copies from fingerprinted assets..."
        css_file=$(grep -o '"assets/app-[^"]*\.css"' priv/static/cache_manifest.json | head -1 | tr -d '"')
        if [ -n "$css_file" ] && [ -f "priv/static/$css_file" ]; then
            cp "priv/static/$css_file" "priv/static/assets/app.css"
            echo "Copied $css_file to app.css"
        fi
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

    echo "Assets built successfully"

    # Create release
    echo "Creating release..."
    MIX_ENV=prod mix release --overwrite

    # Verify release was created
    if [ ! -d "_build/prod/rel/mehr_schulferien" ]; then
        echo "ERROR: Release directory was not created"
        exit 1
    fi

    if [ ! -f "_build/prod/rel/mehr_schulferien/lib/mehr_schulferien-${new_version}/priv/static/cache_manifest.json" ]; then
        echo "ERROR: Static assets not found in release"
        exit 1
    fi

    echo "Release created successfully with static assets"

    # Stop the server before copying files
    sudo /bin/systemctl stop mehr-schulferien2025.service || true

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

    # Run migrations
    "$RELEASE_DIR/bin/mehr_schulferien" eval "MehrSchulferien.ReleaseTasks.migrate"

    # Start the server
    sudo /bin/systemctl start mehr-schulferien2025.service

    # Clean up old backups (keep only the most recent 3)
    find "$HOME/app" -name "release.backup.*" -type d | sort | head -n -3 | xargs -r rm -rf

    logger "Cold deployed release ${new_version} (${commit_hash}) of mehr-schulferien2025."
}

# Main deployment logic
echo "============================================"
echo "Starting deployment at $(date)"
echo "============================================"

if requires_cold_deploy; then
    do_cold_deploy
else
    if ! do_hot_deploy; then
        echo "Hot deploy failed, performing cold deploy..."
        do_cold_deploy
    fi
fi

echo "============================================"
echo "Deployment completed at $(date)"
echo "============================================"
