#!/bin/bash
#
# This script is used to deploy this application to the production server.
# Supports both hot code upgrades (<1s, zero downtime) and cold deploys.
#
# A hot deploy loads the changed modules of this application into the running
# node and ships nothing else. It is used when:
# - Everything else the release is made of is unchanged since the last cold
#   deploy: dependencies, config, priv (static assets and migrations
#   included), runtime versions (release_fingerprint in scripts/deploy_lib.sh)
# - No [cold-deploy] or [restart] tag in commit message
# - Application is currently running
#
# Cold deploy (new release, restart) is used when:
# - Any of the above is not given, or cannot be shown to be given
# - Commit message contains [cold-deploy], [restart], or [supervision]
# - Hot deploy fails, or the node does not report the new version afterwards
#
# Changes to supervised processes or their state need one of the tags: no
# check here can see them.
#
# To upgrade Elixir/Erlang:
# 1. Update .tool-versions with new versions
# 2. Push to master
# 3. Deploy will auto-install new versions via mise and cold deploy

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
# What the running release was built from, written by a cold deploy
FINGERPRINT_FILE="$HOME/app/release.fingerprint"
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

cd "$REPO_DIR" || exit

# shellcheck source=scripts/deploy_lib.sh
source "$REPO_DIR/scripts/deploy_lib.sh"

# Activate mise and install required Elixir/Erlang versions
echo "Setting up mise environment..."
eval "$(mise activate bash)"

# Check if Elixir/Erlang versions changed (for cold deploy detection)
CURRENT_ELIXIR=$(elixir --version 2>/dev/null | grep "Elixir" | awk '{print $2}' || echo "unknown")
CURRENT_ERLANG=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null | tr -d '"' || echo "unknown")

# Install versions from .tool-versions if needed
if [ -f ".tool-versions" ]; then
    echo "Installing tool versions from .tool-versions..."
    mise install
fi

# Check versions after mise install
NEW_ELIXIR=$(elixir --version 2>/dev/null | grep "Elixir" | awk '{print $2}' || echo "unknown")
NEW_ERLANG=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null | tr -d '"' || echo "unknown")

# Detect if runtime versions changed
RUNTIME_CHANGED="false"
if [ "$CURRENT_ELIXIR" != "$NEW_ELIXIR" ] || [ "$CURRENT_ERLANG" != "$NEW_ERLANG" ]; then
    echo "Runtime version change detected!"
    echo "  Elixir: $CURRENT_ELIXIR -> $NEW_ELIXIR"
    echo "  Erlang: $CURRENT_ERLANG -> $NEW_ERLANG"
    RUNTIME_CHANGED="true"
fi

# Get the version and commit info for logging
new_version=$(grep "version: " mix.exs | sed "s/.*version: \"\(.*\)\",/\1/")
commit_msg=$(git log -1 --pretty=%B)
commit_hash=$(git rev-parse --short HEAD)

echo "Deploying version: ${new_version} (${commit_hash})"
echo "Using Elixir: ${NEW_ELIXIR}, Erlang/OTP: ${NEW_ERLANG}"

# Function to check if cold deploy is required
requires_cold_deploy() {
    # Check if runtime versions changed (Elixir/Erlang upgrade)
    if [ "$RUNTIME_CHANGED" = "true" ]; then
        echo "Cold deploy required due to Elixir/Erlang version change"
        return 0
    fi

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

    return 1
}

# Compiles the application and builds the assets, for both kinds of deploy.
#
# The hot deploy runs as the condition of an "if", where "set -e" is off, so
# every step that must not fail says so itself. A failed build that went on
# unnoticed would hot deploy the old modules and report success.
build_app() {
    cp /home/mehrschul2025/conf/prod.secret.exs "$REPO_DIR/config/prod.secret.exs" || return 1
    cd "$REPO_DIR" || return 1
    mix deps.get --only prod || return 1
    MIX_ENV=prod mix compile || return 1

    echo "Building assets..."
    rm -rf priv/static/assets
    rm -f priv/static/cache_manifest.json
    MIX_ENV=prod mix assets.setup || return 1
    MIX_ENV=prod mix assets.deploy || return 1

    # Create non-fingerprinted copies
    if [ -f "priv/static/cache_manifest.json" ]; then
        echo "Creating non-fingerprinted copies from fingerprinted assets..."
        css_file=$(grep -o '"assets/app-[^"]*\.css"' priv/static/cache_manifest.json | head -1 | tr -d '"')
        if [ -n "$css_file" ] && [ -f "priv/static/$css_file" ]; then
            cp "priv/static/$css_file" "priv/static/assets/app.css" || return 1
            echo "Copied $css_file to app.css"
        fi
        js_file=$(grep -o '"assets/app-[^"]*\.js"' priv/static/cache_manifest.json | head -1 | tr -d '"')
        if [ -n "$js_file" ] && [ -f "priv/static/$js_file" ]; then
            cp "priv/static/$js_file" "priv/static/assets/app.js" || return 1
            echo "Copied $js_file to app.js"
        fi
    fi
}

# Function to perform hot deploy
do_hot_deploy() {
    echo "==> Attempting hot code upgrade..."

    build_app || return 1

    # A hot upgrade ships nothing but this application's modules. Everything
    # else has to be what the running release was built from.
    if [ ! -f "$FINGERPRINT_FILE" ]; then
        echo "No fingerprint of the running release - cold deploy required"
        return 1
    fi

    if ! new_fingerprint=$(release_fingerprint "$REPO_DIR" "$ENV_FILE"); then
        echo "Could not fingerprint the build - cold deploy required"
        return 1
    fi

    if [ "$new_fingerprint" != "$(cat "$FINGERPRINT_FILE")" ]; then
        echo "Dependencies, config, priv or assets changed - cold deploy required"
        return 1
    fi

    # Prepare hot upgrade package
    echo "Preparing hot upgrade package..."
    upgrade_version="${new_version}-${commit_hash}"
    upgrade_dir="$HOT_UPGRADES_DIR/$upgrade_version"
    beams_dir="$upgrade_dir/beams"

    rm -rf "$upgrade_dir"
    mkdir -p "$beams_dir" || return 1

    # Copy all compiled beam files. The node loads the ones that differ from
    # its own, now and again when it boots the old release after a restart.
    # A package with a module missing would leave that module on its old code
    # and still report the new version, so the copy has to be complete.
    ebin_dir="_build/prod/lib/mehr_schulferien/ebin"
    cp "$ebin_dir"/*.beam "$beams_dir/" || return 1

    built_count=$(ls -1 "$ebin_dir"/*.beam 2>/dev/null | wc -l)
    beam_count=$(ls -1 "$beams_dir"/*.beam 2>/dev/null | wc -l)
    echo "Prepared $beam_count of $built_count beam files for hot upgrade"

    if [ "$beam_count" -eq 0 ] || [ "$beam_count" -ne "$built_count" ]; then
        echo "Hot upgrade package is incomplete - falling back to cold deploy"
        return 1
    fi

    # Write pending marker to trigger hot upgrade
    echo "$upgrade_version" > "$HOT_UPGRADES_DIR/pending"

    # rpc runs the upgrade inside the running node. eval would start a second
    # VM and upgrade that one.
    echo "Triggering hot code upgrade..."
    result=$("$RELEASE_DIR/bin/mehr_schulferien" rpc "
        case MehrSchulferien.HotDeploy.check_and_apply() do
            {:ok, :upgraded, version} -> IO.puts(\"HOT_UPGRADE_SUCCESS:#{version}\")
            other -> IO.puts(\"HOT_UPGRADE_FAILED:#{inspect(other)}\")
        end
    " 2>&1) || true

    echo "Hot upgrade result: $result"

    # Judge by what the node answers when asked, not by the claim above. No
    # answer means the upgrade did not happen.
    running=$("$RELEASE_DIR/bin/mehr_schulferien" rpc "
        IO.puts(\"DEPLOYED_VERSION:\" <> MehrSchulferien.HotDeploy.deployed_version())
    " 2>&1) || true

    echo "Node reports: $running"

    if echo "$result" | grep -qxF "HOT_UPGRADE_SUCCESS:$upgrade_version" &&
        echo "$running" | grep -qxF "DEPLOYED_VERSION:$upgrade_version"; then
        echo "✅ Hot code upgrade successful!"

        # Clean up old hot upgrade directories (keep last 5)
        cd "$HOT_UPGRADES_DIR" || return 0
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

    build_app || exit 1

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

    # From here on the fingerprint describes a release that is being replaced.
    # Without it the next deploy is cold, should this one stop halfway.
    rm -f "$FINGERPRINT_FILE"

    # Stop the server before copying files
    sudo /bin/systemctl stop mehr-schulferien2025.service || true

    # The new release contains everything a hot upgrade delivered before. A
    # leftover marker would load those older modules over it on boot, also on
    # a start by hand after this deploy stopped halfway.
    rm -f "$HOT_UPGRADES_DIR/current" "$HOT_UPGRADES_DIR/pending"

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

    # Remember what this release was built from: the next deploy may only be
    # hot when its build has the same fingerprint. No file means cold.
    if release_fingerprint "$REPO_DIR" "$ENV_FILE" > "$FINGERPRINT_FILE.tmp"; then
        mv "$FINGERPRINT_FILE.tmp" "$FINGERPRINT_FILE"
    else
        echo "WARNING: could not fingerprint the release - the next deploy will be cold"
        rm -f "$FINGERPRINT_FILE.tmp"
    fi

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
