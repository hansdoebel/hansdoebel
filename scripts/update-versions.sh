#!/bin/bash

README="README.md"

# npm name → README name (only for packages where they differ)
RENAMES=(
    "n8n-nodes-usebouncer:n8n-nodes-bouncer"
    "n8n-nodes-dida:n8n-nodes-dida365"
    "n8n-nodes-devto:n8n-nodes-dev"
)

resolve_readme_name() {
    local npm_name="$1"
    for rename in "${RENAMES[@]}"; do
        if [[ "${rename%%:*}" == "$npm_name" ]]; then
            echo "${rename##*:}"
            return
        fi
    done
    echo "$npm_name"
}

echo "Fetching all packages from npm (single request)..."
RESPONSE=$(curl -s "https://registry.npmjs.org/-/v1/search?text=maintainer:hansdoe&size=250")

PACKAGES=$(echo "$RESPONSE" | jq -r '.objects[] | select(.package.name | startswith("n8n-nodes-")) | "\(.package.name) \(.package.version)"')

if [[ -z "$PACKAGES" ]]; then
    echo "Error: no packages returned from npm"
    exit 1
fi

echo "Updating README..."

SEEN_README_NAMES=""
while IFS=' ' read -r npm_name version; do
    [[ -z "$npm_name" ]] && continue
    readme_name=$(resolve_readme_name "$npm_name")
    SEEN_README_NAMES="$SEEN_README_NAMES $readme_name"

    if grep -q "/hansdoebel/$readme_name)" "$README"; then
        echo "  $readme_name: v$version"
        sed -i '' "s|\($readme_name\)](https://\([^/]*\)/hansdoebel/$readme_name)\*\* — v[0-9.]*|\1](https://\2/hansdoebel/$readme_name)** — v$version|g" "$README"
    else
        echo "  $readme_name: v$version (on npm, not in README)"
    fi
done <<< "$PACKAGES"

README_NAMES=$(grep -oE 'n8n-nodes-[a-z0-9-]+' "$README" | sort -u)
for readme_name in $README_NAMES; do
    if [[ " $SEEN_README_NAMES " != *" $readme_name "* ]]; then
        echo "  WARN: $readme_name in README but not published on npm"
    fi
done

echo "Done!"
