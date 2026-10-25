#!/bin/sh
set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
resolved="$repository_root/Artemis.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
pin=$(ruby -rjson -e '
    pins = JSON.parse(File.read(ARGV.fetch(0))).fetch("pins").select do |entry|
        %w[swiftlint swiftlintplugins].include?(entry.fetch("identity"))
    end
    abort "error: Package.resolved must pin exactly one SwiftLint package." unless pins.length == 1
    entry = pins.first
    version = entry.fetch("state")["version"]
    abort "error: Package.resolved must pin a SwiftLint release version." unless version && !version.empty?
    puts "#{entry.fetch("identity")}:#{version}"
' "$resolved")
lint_identity=${pin%%:*}
lint_version=${pin#*:}
lint_binary=

matches_pinned_version() {
    [ -x "$1" ] || return 1
    candidate_version=$("$1" --version 2>/dev/null) || return 1
    [ "$candidate_version" = "$lint_version" ]
}

# Ignore artifacts from older resolutions, including a different SwiftLint package.
for artifacts in \
    "${BUILD_DIR:-$repository_root/build/Products}/../../SourcePackages/artifacts" \
    "$repository_root/build/test-derived-data/SourcePackages/artifacts" \
    "$repository_root/.SwiftPackages/artifacts"; do
    for candidate in \
        "$artifacts/$lint_identity/SwiftLintBinary/"*.artifactbundle/macos/swiftlint \
        "$artifacts/$lint_identity/SwiftLintBinary/"*.artifactbundle/swiftlint-*-macos/bin/swiftlint; do
        if matches_pinned_version "$candidate"; then
            lint_binary=$candidate
            break 2
        fi
    done
done

if [ -z "$lint_binary" ]; then
    lint_binary=$(command -v swiftlint || true)
fi
if [ -z "$lint_binary" ] || ! matches_pinned_version "$lint_binary"; then
    echo "error: SwiftLint $lint_version from pinned package $lint_identity is unavailable. Resolve Swift package dependencies or install the matching SwiftLint version." >&2
    exit 1
fi

cd "$repository_root"
exec "$lint_binary" lint --strict --config "$repository_root/.swiftlint.yml" "$@"
