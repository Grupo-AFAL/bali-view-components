#!/bin/bash
# entrypoint-sandbox.sh
# Configures GitHub authentication when GH_TOKEN is available
# Used by Docker Sandbox for git push operations

set -e

# Configure gh CLI for git operations if token is available
if [ -n "$GH_TOKEN" ]; then
  echo "Configuring GitHub authentication via gh CLI..."
  echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null && \
    gh auth setup-git 2>/dev/null && \
    echo "GitHub auth configured" || true
fi

# Execute the command passed to the container
exec "$@"
