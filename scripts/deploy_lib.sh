#!/bin/bash
#
# Functions for scripts/deploy.sh. Sourcing this file has no side effects, so
# the functions can be tested (test/scripts/deploy_lib_test.exs).

# Prints a fingerprint of everything in a build that a hot upgrade does NOT
# ship. A hot upgrade only replaces the modules of this application. A release
# also consists of the dependencies, the config, priv (static assets and
# migrations included), the runtime versions and the project settings in
# mix.exs. When the fingerprint of a new build differs from the one of the
# running release, only a cold deploy brings all of the commit live.
#
# $1    the repository, built for prod
# $2... further files the release depends on (the environment file)
#
# Left out on purpose: the version line of mix.exs (it changes with every
# deploy), cache_manifest.json and *.gz (rewritten by every asset build, the
# assets themselves are covered) and priv/static/cache (written at runtime).
#
# Not covered here:
# - Consolidated protocols. Their files come out with different bytes after a
#   full recompile of the same code, so they cannot be compared. They follow
#   from the dependencies (mix.lock) and from this application's own
#   implementations, and MehrSchulferien.HotDeploy refuses an upgrade that
#   brings one.
# - State held by running processes: a changed supervision tree or GenServer
#   state needs [cold-deploy] in the commit message. No check can see it.
release_fingerprint() {
    local repo="$1"
    shift

    local ebin="_build/prod/lib/mehr_schulferien/ebin"

    # No build, no fingerprint: a hash over half of the inputs would compare
    # equal to the next half and wave a hot upgrade through.
    local required
    for required in "$repo/mix.exs" "$repo/mix.lock" "$repo/config" "$repo/priv" \
        "$repo/$ebin" "$@"; do
        if [ ! -e "$required" ]; then
            echo "release_fingerprint: $required is missing" >&2
            return 1
        fi
    done

    local fingerprint
    fingerprint=$(
        set -o pipefail
        cd "$repo" || exit 1

        {
            grep -vE '^[[:space:]]*version: "' mix.exs

            {
                echo mix.lock
                [ -f .tool-versions ] && echo .tool-versions
                find config priv -type f \
                    ! -name cache_manifest.json \
                    ! -name '*.gz' \
                    ! -path 'priv/static/cache/*'
                [ -d rel ] && find rel -type f
                for extra in "$@"; do echo "$extra"; done
            } | LC_ALL=C sort | while IFS= read -r file; do
                # The name and the content, so a renamed file counts as well
                echo "== $file"
                cat "$file" || exit 1
            done
        } | sha256sum | cut -d' ' -f1
    ) || return 1

    echo "$fingerprint"
}
