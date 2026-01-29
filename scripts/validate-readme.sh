#!/bin/bash

README="README.md"
ERRORS=0

echo "Validating README.md..."

if [[ ! -f "$README" ]]; then
    echo "  ✗ README.md not found"
    exit 1
fi

if ! grep -q "^### .* Hello there" "$README"; then
    echo "  ✗ Missing header section"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -q "#### Latest Projects" "$README"; then
    echo "  ✗ Missing 'Latest Projects' section"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -q "What I Use Every Day" "$README"; then
    echo "  ✗ Missing 'What I Use Every Day' section"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -q "What I'm Currently Learning" "$README"; then
    echo "  ✗ Missing 'What I'm Currently Learning' section"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -q "#### Statistics" "$README"; then
    echo "  ✗ Missing 'Statistics' section"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -qE "^\*Last updated on [A-Z][a-z]+ [0-9]{2}, [0-9]{4}\*$" "$README"; then
    echo "  ✗ Invalid or missing 'Last updated' date format (expected: *Last updated on Month DD, YYYY*)"
    ERRORS=$((ERRORS + 1))
fi

while IFS= read -r line; do
    if echo "$line" | grep -qE "n8n-nodes-[a-z-]+\)" && ! echo "$line" | grep -qE "— v[0-9]+\.[0-9]+"; then
        echo "  ✗ Missing version for: $(echo "$line" | grep -oE 'n8n-nodes-[a-z-]+')"
        ERRORS=$((ERRORS + 1))
    fi
done < "$README"

if grep -qE '\[[^\]]*$|\([^\)]*$' "$README"; then
    echo "  ✗ Possible unclosed markdown brackets detected"
    ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -eq 0 ]]; then
    echo "  ✓ README.md is valid"
    exit 0
else
    echo ""
    echo "Found $ERRORS error(s). Please fix before pushing."
    exit 1
fi
