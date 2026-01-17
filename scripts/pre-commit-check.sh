#!/bin/bash
#
# Pre-Commit Check Hook for Claude Code
# Validates that tests pass for staged component files before allowing commit
#

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Get staged component files (only from app/components/bali/)
staged_components=$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null | \
  grep "^app/components/bali/" | \
  cut -d'/' -f4 | \
  sort -u)

# If no component files are staged, allow the commit
if [ -z "$staged_components" ]; then
  exit 0
fi

# Run tests for each staged component
failed=0
tested=0

for component in $staged_components; do
  # Skip if it's a file not a directory (e.g., application_component.rb)
  if [ ! -d "$REPO_ROOT/app/components/bali/$component" ]; then
    continue
  fi

  spec_file="$REPO_ROOT/spec/bali/components/${component}_spec.rb"

  if [ -f "$spec_file" ]; then
    ((tested++))
    echo "Testing: $component"

    if ! bundle exec rspec "$spec_file" --format progress --no-color 2>/dev/null; then
      echo "FAIL: $component tests failed"
      failed=1
    fi
  fi
done

# If any tests failed, block the commit
if [ $failed -eq 1 ]; then
  echo ""
  echo "BLOCKED: Component tests failed. Fix before committing."
  exit 1
fi

# All tests passed (or no tests found)
if [ $tested -gt 0 ]; then
  echo "All $tested component test(s) passed."
fi

exit 0
