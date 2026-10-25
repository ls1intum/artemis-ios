#!/bin/sh
set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
lint_binary=

# Prefer the binary fetched from Package.resolved over a machine-specific installation.
for artifacts in \
    "${BUILD_DIR:-$repository_root/build/Products}/../../SourcePackages/artifacts" \
    "$repository_root/build/test-derived-data/SourcePackages/artifacts" \
    "$repository_root/.SwiftPackages/artifacts"; do
    for candidate in "$artifacts"/swiftlint/SwiftLintBinary/*.artifactbundle/swiftlint-*-macos/bin/swiftlint; do
        if [ -x "$candidate" ]; then
            lint_binary=$candidate
            break 2
        fi
    done
done

if [ -z "$lint_binary" ]; then
    lint_binary=$(command -v swiftlint || true)
fi
if [ -z "$lint_binary" ]; then
    echo "error: SwiftLint is unavailable. Resolve Swift package dependencies or install SwiftLint." >&2
    exit 1
fi

cd "$repository_root"
exec "$lint_binary" lint --strict --config "$repository_root/.swiftlint.yml" "$@"
