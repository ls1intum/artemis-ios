#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]] || [[ "${1:-}" != iphonesimulator && "${1:-}" != iphoneos ]]; then
    echo "error: Usage: select-ci-xcode.sh {iphonesimulator|iphoneos}" >&2
    exit 1
fi
required_sdk=$1

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
minimum_swift=$(sed -nE '1s|^//[[:space:]]*swift-tools-version:[[:space:]]*([0-9]+\.[0-9]+(\.[0-9]+)?)[[:space:]]*$|\1|p' "$repository_root/ArtemisKit/Package.swift")
if [[ -z "$minimum_swift" ]]; then
    echo "error: ArtemisKit/Package.swift must begin with a numeric swift-tools-version." >&2
    exit 1
fi

version_at_least() {
    awk -v candidate="$1" -v required="$2" 'BEGIN {
        split(candidate, c, "."); split(required, r, ".")
        for (i = 1; i <= 3; i++) {
            if (c[i] + 0 > r[i] + 0) exit 0
            if (c[i] + 0 < r[i] + 0) exit 1
        }
        exit 0
    }'
}

inspect_toolchain() {
    local developer_directory=$1
    echo "Toolchain: $developer_directory"
    if ! xcode_details=$(DEVELOPER_DIR="$developer_directory" xcodebuild -version 2>&1); then
        printf 'Unavailable: %s\n' "$xcode_details"
        return 1
    fi
    if ! swift_details=$(DEVELOPER_DIR="$developer_directory" xcrun swift --version 2>&1); then
        printf '%s\nUnavailable: %s\n' "$xcode_details" "$swift_details"
        return 1
    fi
    printf '%s\n%s\n' "$xcode_details" "$swift_details"
    if ! sdk_path=$(DEVELOPER_DIR="$developer_directory" xcrun --sdk "$required_sdk" --show-sdk-path 2>&1); then
        printf 'Unavailable SDK %s: %s\n' "$required_sdk" "$sdk_path"
        return 1
    fi
    if [[ ! -d "$sdk_path" ]]; then
        printf 'Unavailable SDK %s: path does not exist: %s\n' "$required_sdk" "$sdk_path"
        return 1
    fi
    printf 'SDK %s: %s\n' "$required_sdk" "$sdk_path"
    xcode_version=$(printf '%s\n' "$xcode_details" | sed -nE 's/^Xcode ([0-9]+(\.[0-9]+)+)$/\1/p')
    build_version=$(printf '%s\n' "$xcode_details" | sed -n 's/^Build version //p')
    swift_version=$(printf '%s\n' "$swift_details" | sed -nE 's/.*Swift version ([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p')
    [[ -n "$xcode_version" && -n "$swift_version" ]]
}

select_toolchain() {
    printf 'DEVELOPER_DIR=%s\n' "$1" >> "${GITHUB_ENV:?GITHUB_ENV must be set}"
    echo "Selected DEVELOPER_DIR=$1"
}

echo "Required Swift $minimum_swift from ArtemisKit/Package.swift"
echo "Required SDK: $required_sdk"
echo "Available Xcode toolchains:"
current_directory=${DEVELOPER_DIR:-$(xcode-select --print-path 2>/dev/null || true)}
if [[ -n "$current_directory" ]] && inspect_toolchain "$current_directory" && version_at_least "$swift_version" "$minimum_swift"; then
    select_toolchain "$current_directory"
    exit 0
fi

applications_directory=${ARTEMIS_XCODE_APPLICATIONS_DIRECTORY:-/Applications}
selected_directory=
selected_version=0
found_installed=false
for application in "$applications_directory"/Xcode*.app; do
    developer_directory=$application/Contents/Developer
    [[ -d "$developer_directory" ]] || continue
    found_installed=true
    if ! inspect_toolchain "$developer_directory"; then
        continue
    fi
    # Keep prereleases visible in the inventory, but choose stable fallbacks.
    case "${application##*/}" in
        *[Bb][Ee][Tt][Aa]*|*[Rr][Cc]*|*[Pp][Rr][Ee][Vv][Ii][Ee][Ww]*) continue ;;
    esac
    [[ "$build_version" =~ ^[0-9]+[A-Z][0-9]+$ ]] || continue
    if version_at_least "$swift_version" "$minimum_swift" && version_at_least "$xcode_version" "$selected_version"; then
        selected_directory=$developer_directory
        selected_version=$xcode_version
    fi
done

if [[ -z "$selected_directory" ]]; then
    if [[ "$found_installed" == false ]]; then
        echo "No installed Xcode applications found in $applications_directory."
    fi
    echo "error: No compatible stable Xcode is installed. Swift $minimum_swift or newer and SDK $required_sdk are required; available toolchains are listed above." >&2
    exit 1
fi
select_toolchain "$selected_directory"
