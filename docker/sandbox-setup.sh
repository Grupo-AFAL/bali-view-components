#!/bin/bash
# sandbox-setup.sh
# Run once after entering the sandbox to install plugins and dependencies.
#
# Usage (inside sandbox):
#   bash docker/sandbox-setup.sh

set -e

echo "=== Bali ViewComponents Sandbox Setup ==="

# 1. GitHub authentication
if [ -n "$GH_TOKEN" ]; then
  echo "Configuring GitHub authentication..."
  echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null && \
    gh auth setup-git 2>/dev/null && \
    echo "GitHub auth configured" || true
fi

# 2. Install Claude Code plugins
# Uses `claude plugin` CLI subcommands (non-interactive, scriptable)
echo ""
echo "=== Adding plugin marketplaces ==="
claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>&1 || echo "  -> OMC marketplace skipped"
claude plugin marketplace add https://github.com/anthropics/claude-plugins-official 2>&1 || echo "  -> Official marketplace skipped"
claude plugin marketplace add https://github.com/zerobearing2/rails-ai 2>&1 || echo "  -> Rails AI marketplace skipped"

echo ""
echo "=== Installing Claude Code plugins ==="
for plugin in \
  "oh-my-claudecode" \
  "superpowers" \
  "rails-ai" \
  "commit-commands" \
  "code-review"; do
  echo "Installing $plugin..."
  claude plugin install "$plugin" --scope user 2>&1 || echo "  -> $plugin skipped"
done

# 3. Install Ruby dependencies
echo ""
echo "=== Installing Ruby dependencies ==="
bundle install

# 4. Install JS dependencies
echo ""
echo "=== Installing JS dependencies ==="
yarn install

# 5. Prepare dummy app database
echo ""
echo "=== Preparing database ==="
cd spec/dummy && bin/rails db:prepare && cd ../..

echo ""
echo "=== Setup complete! ==="
echo "Run 'claude' to start Claude Code"
echo "Run 'bundle exec rspec' to run Ruby specs"
echo "Run 'yarn cy:run:electron' to run Cypress tests"
