#!/bin/bash
#
# Update Quality Score in MIGRATION_STATUS.md
#
# Usage:
#   ./scripts/update-quality-score.sh ComponentName 9
#   ./scripts/update-quality-score.sh Button 8
#   ./scripts/update-quality-score.sh --from-results  # Update all from .claude/review-results/

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_FILE="$REPO_ROOT/MIGRATION_STATUS.md"
RESULTS_DIR="$REPO_ROOT/.claude/review-results"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to update a single component's score
update_score() {
    local component=$1
    local score=$2

    # Convert component name to match the format in MIGRATION_STATUS.md
    # e.g., "button" -> "Button", "bulk_actions" -> "BulkActions"
    # Use Ruby for reliable cross-platform PascalCase conversion
    local formatted_name=$(ruby -e "puts '$component'.split('_').map(&:capitalize).join")

    # Check if component exists in the Component Verification Matrix
    # Match lines that start with | ComponentName (with possible trailing spaces)
    if ! grep -E "^\| ${formatted_name}[[:space:]]+\|" "$STATUS_FILE" | head -1 | grep -q "Tests"; then
        # Try to find in the matrix section (has Tests column in header)
        if ! grep -E "^\| ${formatted_name}[[:space:]]+\|.*\|.*\|.*\|.*\|.*-.*\|" "$STATUS_FILE" > /dev/null; then
            echo "Component '$formatted_name' not found in MIGRATION_STATUS.md matrix"
            return 1
        fi
    fi

    # Update the Quality column (6th data column = column between Manual and Notes)
    # The pattern: | Name | Tests | AI Visual | DaisyUI | Manual | Quality | Notes |
    # We need to replace the "-" with the score in the Quality column
    sed -i.bak -E "s/(^\| ${formatted_name}[[:space:]]+\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|)[[:space:]]*-[[:space:]]*\|/\1  ${score}\/10  |/" "$STATUS_FILE"

    # Also handle if there's already a score (for updates)
    sed -i.bak -E "s/(^\| ${formatted_name}[[:space:]]+\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|)[[:space:]]*[0-9]+\/10[[:space:]]*\|/\1  ${score}\/10  |/" "$STATUS_FILE"

    rm -f "$STATUS_FILE.bak"

    echo -e "${GREEN}✓${NC} Updated $formatted_name to ${score}/10"
}

# Function to update from all result files
update_from_results() {
    if [ ! -d "$RESULTS_DIR" ]; then
        echo "No results directory found at $RESULTS_DIR"
        exit 1
    fi

    local count=0
    for result_file in "$RESULTS_DIR"/*.json; do
        if [ -f "$result_file" ]; then
            component=$(jq -r '.component // empty' "$result_file" 2>/dev/null)
            score=$(jq -r '.score // empty' "$result_file" 2>/dev/null)

            if [ -n "$component" ] && [ -n "$score" ] && [ "$score" != "null" ]; then
                update_score "$component" "$score"
                ((count++))
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}Updated $count component scores${NC}"
}

# Function to add changelog entry
add_changelog_entry() {
    local component=$1
    local score=$2
    local date=$(date +%Y-%m-%d)

    # Convert component name
    local formatted_name=$(echo "$component" | sed -E 's/(^|_)([a-z])/\U\2/g')

    # Add to changelog section
    local changelog_line="| $date | $formatted_name | Quality review: $score/10 | AI |"

    # Find the Change Log section and append after the header
    # This is a bit tricky with sed, so we'll use a different approach
    if grep -q "^## Change Log" "$STATUS_FILE"; then
        # Append after the last entry in the changelog table
        # Find line number of last table entry before next section or EOF
        local last_entry_line=$(grep -n "^| [0-9]" "$STATUS_FILE" | tail -1 | cut -d: -f1)
        if [ -n "$last_entry_line" ]; then
            sed -i.bak "${last_entry_line}a\\
$changelog_line" "$STATUS_FILE"
            rm -f "$STATUS_FILE.bak"
        fi
    fi
}

# Function to update summary counts
update_summary() {
    echo -e "${YELLOW}Note: Summary counts should be updated manually or by running a full audit${NC}"
}

# Main
if [ "$1" = "--from-results" ]; then
    update_from_results
    update_summary
elif [ $# -eq 2 ]; then
    component=$1
    score=$2

    if ! [[ "$score" =~ ^[0-9]+$ ]] || [ "$score" -lt 1 ] || [ "$score" -gt 10 ]; then
        echo "Score must be a number between 1 and 10"
        exit 1
    fi

    update_score "$component" "$score"
    add_changelog_entry "$component" "$score"
else
    echo "Usage:"
    echo "  $0 ComponentName score    # Update single component"
    echo "  $0 --from-results         # Update all from review results"
    echo ""
    echo "Examples:"
    echo "  $0 Button 9"
    echo "  $0 bulk_actions 8"
    echo "  $0 --from-results"
    exit 1
fi
