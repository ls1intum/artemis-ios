#!/bin/bash
set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root"
ruby_version=$(tr -d '[:space:]' < "$repository_root/.ruby-version")
case "$ruby_version" in
    ''|*[!0-9.]*) echo "error: .ruby-version must contain a numeric Ruby release." >&2; exit 1 ;;
esac

# Self-hosted runners do not automatically install versions selected by Renovate.
# Build the missing release with a pinned ruby-build instead of upgrading runner tools.
rbenv_binary=$(command -v rbenv || true)
if [[ -z "$rbenv_binary" && -x /opt/homebrew/bin/rbenv ]]; then
    rbenv_binary=/opt/homebrew/bin/rbenv
fi
if [[ -z "$rbenv_binary" ]]; then
    echo "error: Install rbenv on the self-hosted macOS runner." >&2
    exit 1
fi
export PATH="/opt/homebrew/bin:$PATH"
ruby_prefix=$("$rbenv_binary" root)/versions/$ruby_version
if [[ ! -x "$ruby_prefix/bin/ruby" ]]; then
    build_directory=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/artemis-ruby-build.XXXXXX")
    trap 'rm -rf "$build_directory"' EXIT
    git -C "$build_directory" init --quiet
    git -C "$build_directory" remote add origin https://github.com/rbenv/ruby-build.git
    git -C "$build_directory" fetch --quiet --depth 1 origin b6a92c15f0df872047c74f7dfa0b92dfd4de8a92
    git -C "$build_directory" checkout --quiet --detach FETCH_HEAD
    "$build_directory/bin/ruby-build" "$ruby_version" "$ruby_prefix"
fi

export PATH="$ruby_prefix/bin:$PATH"
ruby --version
bundler_version=$(awk '/^BUNDLED WITH$/ { getline; gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print; exit }' "$repository_root/Gemfile.lock")
gem install bundler --version "$bundler_version" --no-document
bundle config set --local path vendor/bundle
bundle install
# Keep subsequent workflow steps on this Ruby, without shell-specific rbenv initialization.
printf '%s\n' "$ruby_prefix/bin" >> "$GITHUB_PATH"
