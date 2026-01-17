#!/bin/bash
#
# Batch Review Script for Bali Components
# Runs parallel autonomous review cycles using git worktrees
#
# Usage:
#   ./scripts/batch-review.sh                    # Review all components
#   ./scripts/batch-review.sh Button Modal Card  # Review specific components
#   ./scripts/batch-review.sh --list             # List components to review
#
# Options:
#   --parallel N      Run N reviews in parallel (default: 6)
#   --dry-run         Show what would be done without executing
#   --list            List all components and exit
#   --skip-cleanup    Don't remove worktrees after completion
#   --code-only       Skip visual verification (faster, recommended for bulk)
#   --with-visual     Include visual verification (slower, needs port coordination)
#   --base-port N     Starting port for Lookbook servers (default: 3001)

set -e

# Configuration
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKTREE_BASE="/tmp/bali-reviews"
RESULTS_DIR="$REPO_ROOT/.claude/review-results"
LOG_DIR="$REPO_ROOT/.claude/review-logs"
PARALLEL=6
DRY_RUN=false
SKIP_CLEANUP=false
BASE_BRANCH="tailwind-migration"
CODE_ONLY=true  # Default to code-only for parallel safety
BASE_PORT=3001

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
COMPONENTS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list)
            echo "Available components:"
            ls -1 "$REPO_ROOT/app/components/bali" | grep -v application | sort
            exit 0
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=true
            shift
            ;;
        --code-only)
            CODE_ONLY=true
            shift
            ;;
        --with-visual)
            CODE_ONLY=false
            shift
            ;;
        --base-port)
            BASE_PORT="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            COMPONENTS+=("$1")
            shift
            ;;
    esac
done

# If no components specified, get all from directory
if [ ${#COMPONENTS[@]} -eq 0 ]; then
    while IFS= read -r line; do
        COMPONENTS+=("$line")
    done < <(ls -1 "$REPO_ROOT/app/components/bali" | grep -v application | sort)
fi

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Bali Batch Review                  ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "Components: ${#COMPONENTS[@]}"
echo -e "Parallel:   $PARALLEL"
echo -e "Mode:       $([ "$CODE_ONLY" = true ] && echo 'Code-only (fast)' || echo 'With visual (slower)')"
echo -e "Dry run:    $DRY_RUN"
if [ "$CODE_ONLY" = false ]; then
    echo -e "Port range: $BASE_PORT-$((BASE_PORT + PARALLEL - 1))"
fi
echo ""

if [ "$CODE_ONLY" = false ]; then
    echo -e "${YELLOW}Note: Visual mode requires starting Lookbook servers.${NC}"
    echo -e "${YELLOW}Each parallel slot uses its own port (3001, 3002, etc.)${NC}"
    echo ""
fi

# Create directories
mkdir -p "$WORKTREE_BASE"
mkdir -p "$RESULTS_DIR"
mkdir -p "$LOG_DIR"

# Function to get assigned port for a slot
get_port_for_slot() {
    local slot=$1
    echo $((BASE_PORT + slot))
}

# Function to start Lookbook server for a worktree
start_lookbook_server() {
    local worktree_path=$1
    local port=$2
    local pid_file="$worktree_path/.lookbook.pid"

    cd "$worktree_path/spec/dummy"
    PORT=$port bin/rails server -p $port -d 2>/dev/null
    echo $! > "$pid_file"

    # Wait for server to be ready
    for i in {1..30}; do
        if curl -s "http://localhost:$port/lookbook" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Function to stop Lookbook server
stop_lookbook_server() {
    local worktree_path=$1
    local pid_file="$worktree_path/.lookbook.pid"

    if [ -f "$pid_file" ]; then
        kill $(cat "$pid_file") 2>/dev/null || true
        rm -f "$pid_file"
    fi
}

# Function to run a single review
run_review() {
    local component=$1
    local slot=${2:-0}  # Slot number for port assignment
    local worktree_path="$WORKTREE_BASE/$component"
    local log_file="$LOG_DIR/${component}.log"
    local result_file="$RESULTS_DIR/${component}.json"
    local port=$(get_port_for_slot $slot)

    echo -e "${YELLOW}[START]${NC} $component (slot $slot, port $port)"

    if $DRY_RUN; then
        echo "  Would create worktree: $worktree_path"
        if [ "$CODE_ONLY" = true ]; then
            echo "  Would run: claude -p '/review-cycle $component --code-only'"
        else
            echo "  Would start Lookbook on port $port"
            echo "  Would run: claude -p '/review-cycle $component' with LOOKBOOK_PORT=$port"
        fi
        return 0
    fi

    # Create worktree if it doesn't exist
    if [ ! -d "$worktree_path" ]; then
        git -C "$REPO_ROOT" worktree add "$worktree_path" "$BASE_BRANCH" 2>/dev/null || true
    fi

    cd "$worktree_path"

    # For visual mode, start Lookbook server
    if [ "$CODE_ONLY" = false ]; then
        echo -e "  Starting Lookbook on port $port..."
        if ! start_lookbook_server "$worktree_path" "$port"; then
            echo -e "${RED}[FAIL]${NC} $component - Could not start Lookbook server"
            return 1
        fi
    fi

    # Create the prompt based on mode
    local mode_flag=""
    local env_vars=""
    if [ "$CODE_ONLY" = true ]; then
        mode_flag="--code-only"
    else
        env_vars="LOOKBOOK_PORT=$port LOOKBOOK_URL=http://localhost:$port/lookbook"
    fi

    # Create a prompt file for the review
    cat > "/tmp/review-prompt-${component}.txt" << EOF
/review-cycle $component $mode_flag

After completing the review cycle, output a JSON summary to stdout with this format:
{
  "component": "$component",
  "status": "SUCCESS|PARTIAL|BLOCKED",
  "score": <number>,
  "iterations": <number>,
  "issues_fixed": <number>,
  "commit": "<hash or null>",
  "errors": []
}
EOF

    # Run Claude (this will use the pre-configured permissions)
    if $env_vars claude -p "$(cat /tmp/review-prompt-${component}.txt)" \
        --output-format json \
        > "$result_file" 2> "$log_file"; then
        echo -e "${GREEN}[DONE]${NC} $component (score: $(jq -r '.score // "?"' "$result_file" 2>/dev/null))"
    else
        echo -e "${RED}[FAIL]${NC} $component - see $log_file"
    fi

    # Cleanup
    rm -f "/tmp/review-prompt-${component}.txt"

    # Stop Lookbook server if we started one
    if [ "$CODE_ONLY" = false ]; then
        stop_lookbook_server "$worktree_path"
    fi
}

# Export functions and variables for parallel execution
export -f run_review get_port_for_slot start_lookbook_server stop_lookbook_server
export WORKTREE_BASE RESULTS_DIR LOG_DIR DRY_RUN REPO_ROOT BASE_BRANCH CODE_ONLY BASE_PORT
export RED GREEN YELLOW BLUE NC

# Run reviews in parallel with slot assignment
echo -e "${BLUE}Starting reviews...${NC}"
echo ""

# Create a temporary file with component:slot pairs
SLOT_FILE=$(mktemp)
slot=0
for component in "${COMPONENTS[@]}"; do
    echo "$component $((slot % PARALLEL))" >> "$SLOT_FILE"
    ((slot++))
done

if command -v parallel &> /dev/null; then
    # Use GNU parallel if available - it handles slots automatically
    cat "$SLOT_FILE" | parallel -j "$PARALLEL" --colsep ' ' run_review {1} {2}
else
    # Fallback: process in batches to manage slots
    batch=0
    while IFS= read -r line; do
        component=$(echo "$line" | cut -d' ' -f1)
        slot=$(echo "$line" | cut -d' ' -f2)
        run_review "$component" "$slot" &
        ((batch++))
        if [ $((batch % PARALLEL)) -eq 0 ]; then
            wait  # Wait for batch to complete before next
        fi
    done < "$SLOT_FILE"
    wait  # Wait for final batch
fi

rm -f "$SLOT_FILE"

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Results Summary                    ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Summarize results
success=0
partial=0
blocked=0
failed=0

for component in "${COMPONENTS[@]}"; do
    result_file="$RESULTS_DIR/${component}.json"
    if [ -f "$result_file" ]; then
        status=$(jq -r '.status // "UNKNOWN"' "$result_file" 2>/dev/null || echo "UNKNOWN")
        score=$(jq -r '.score // "?"' "$result_file" 2>/dev/null || echo "?")
        case $status in
            SUCCESS)
                echo -e "${GREEN}✓${NC} $component (score: $score)"
                ((success++))
                ;;
            PARTIAL)
                echo -e "${YELLOW}~${NC} $component (score: $score)"
                ((partial++))
                ;;
            BLOCKED)
                echo -e "${RED}✗${NC} $component (score: $score)"
                ((blocked++))
                ;;
            *)
                echo -e "${RED}?${NC} $component (unknown status)"
                ((failed++))
                ;;
        esac
    else
        echo -e "${RED}?${NC} $component (no result file)"
        ((failed++))
    fi
done

echo ""
echo -e "Success: ${GREEN}$success${NC}"
echo -e "Partial: ${YELLOW}$partial${NC}"
echo -e "Blocked: ${RED}$blocked${NC}"
echo -e "Failed:  ${RED}$failed${NC}"
echo ""

# Update MIGRATION_STATUS.md with results
if ! $DRY_RUN && [ $success -gt 0 ] || [ $partial -gt 0 ]; then
    echo -e "${BLUE}Updating MIGRATION_STATUS.md...${NC}"
    "$REPO_ROOT/scripts/update-quality-score.sh" --from-results
fi

# Cleanup worktrees unless skipped
if ! $SKIP_CLEANUP && ! $DRY_RUN; then
    echo -e "${BLUE}Cleaning up worktrees...${NC}"
    for component in "${COMPONENTS[@]}"; do
        worktree_path="$WORKTREE_BASE/$component"
        if [ -d "$worktree_path" ]; then
            git -C "$REPO_ROOT" worktree remove "$worktree_path" --force 2>/dev/null || true
        fi
    done
    rmdir "$WORKTREE_BASE" 2>/dev/null || true
fi

echo -e "${GREEN}Done!${NC}"
echo ""
echo "Results saved to: $RESULTS_DIR"
echo "Logs saved to: $LOG_DIR"
