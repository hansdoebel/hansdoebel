#!/bin/bash

README="README.md"
TEMP_DIR=$(mktemp -d)

PACKAGES=(
    "n8n-nodes-bouncer"
    "n8n-nodes-dida:n8n-nodes-dida365"
    "n8n-nodes-dnsimple"
    "n8n-nodes-docling-serve"
    "n8n-nodes-docusign"
    "n8n-nodes-dub"
    "n8n-nodes-monday-pro"
    "n8n-nodes-onoffice:n8n-nodes-onoffice-pro"
    "n8n-nodes-paperless"
    "n8n-nodes-sevalla"
    "n8n-nodes-ticketmaster"
    "n8n-nodes-ticktick"
    "n8n-nodes-tripadvisor"
)

fetch_version() {
    local entry="$1"
    local temp_dir="$2"

    if [[ "$entry" == *":"* ]]; then
        npm_pkg="${entry%%:*}"
        readme_pkg="${entry##*:}"
    else
        npm_pkg="$entry"
        readme_pkg="$entry"
    fi

    version=$(curl -s "https://registry.npmjs.org/$npm_pkg/latest" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)

    echo "$readme_pkg:$version" > "$temp_dir/$readme_pkg"
}

echo "Fetching latest versions from npm (parallel)..."

for entry in "${PACKAGES[@]}"; do
    fetch_version "$entry" "$TEMP_DIR" &
done

wait

echo "Updating README..."

for entry in "${PACKAGES[@]}"; do
    if [[ "$entry" == *":"* ]]; then
        readme_pkg="${entry##*:}"
    else
        readme_pkg="$entry"
    fi

    if [[ -f "$TEMP_DIR/$readme_pkg" ]]; then
        result=$(cat "$TEMP_DIR/$readme_pkg")
        version="${result##*:}"

        if [[ -n "$version" ]]; then
            echo "  $readme_pkg: v$version"
            sed -i '' "s|\($readme_pkg\)](https://github.com/hansdoebel/$readme_pkg)\*\* — v[0-9.]*|\1](https://github.com/hansdoebel/$readme_pkg)** — v$version|g" "$README"
        else
            echo "  $readme_pkg: (not found on npm)"
        fi
    fi
done

rm -rf "$TEMP_DIR"

echo "Done!"
