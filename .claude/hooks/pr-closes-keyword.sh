#!/bin/bash
#
# PreToolUse (Bash) — stops a PR from being opened or edited when its body tries
# to close an issue IN SPANISH.
#
# Why it exists: GitHub only closes the issue on merge if the PR body carries one
# of its keywords, and every one of them is English —`Closes`, `Fixes`,
# `Resolves` and their variants—. «Cierra #123» is dead text: it reads just as
# well, closes nothing, and the issue stays open with nobody the wiser until
# someone sweeps it by hand. It happened dozens of times.
#
# This is not a reminder, it is a gate: the command does not run.
#
# Hook contract: it receives the call's JSON on stdin and decides by exit code
# — 0 lets it through, 2 blocks and hands Claude whatever is printed on stderr.
# Any other failure (jq missing, odd JSON) lets it through: a broken gate cannot
# turn into a plug for everything else.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0

# The commands that publish a PR body: `gh pr create|edit`, and the REST call the team uses
# when GraphQL is rate-limited — `gh api repos/<owner>/<repo>/pulls[/N]` with a `body` field.
printf '%s' "$COMMAND" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+(create|edit)|gh[[:space:]]+api[[:space:]].*pulls' || exit 0

# The Spanish verb, followed by an issue. `arregla|corrige|resuelve|cierra` are
# the four that write themselves when one is drafting in Spanish.
PATTERN='(^|[^[:alnum:]])([Cc]ierra|[Cc]ierran|[Rr]esuelve|[Rr]esuelven|[Cc]orrige|[Aa]rregla)[[:space:]]+#[0-9]+'

# The body travels as a file — `--body-file path`, or `-F body=@path` through `gh api` — or
# inline, which is checked against the command itself.
BODY=""
BODY_FILE=$(printf '%s' "$COMMAND" | sed -nE "s/.*--body-file[[:space:]]+('([^']*)'|\"([^\"]*)\"|([^[:space:]]+)).*/\2\3\4/p")
if [ -z "$BODY_FILE" ]; then
  BODY_FILE=$(printf '%s' "$COMMAND" | sed -nE "s/.*(-F|--field)[[:space:]]+['\"]?body=@([^'\"[:space:]]+).*/\2/p")
fi
if [ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ]; then
  BODY=$(cat "$BODY_FILE")
else
  BODY="$COMMAND"
fi

printf '%s' "$BODY" | grep -Eq "$PATTERN" || exit 0

OFFENDERS=$(printf '%s' "$BODY" | grep -Eo "$PATTERN" | head -3 | sed 's/^/    /')

cat >&2 <<EOF
The PR body tries to close an issue in Spanish and GitHub does not understand it:

$OFFENDERS

GitHub ONLY closes the issue on merge with its own keywords, and every one of
them is English: Closes / Fixes / Resolves (and closed/fixed/resolved).
«Cierra #123» reads well and closes nothing — the issue stays open.

Change it to «Closes #123» (the rest of the body can stay in Spanish) and run
the command again.
EOF
exit 2
