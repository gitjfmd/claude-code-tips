#!/usr/bin/env bash
# sync-central-policy.sh — WHAT: pull central-command dev's policies-procedures/ into
# <root>/central-command/policies-procedures/ (the policy DATA mirror every repo root
# carries; AGENTS.md Refs starting /central-command/policies-procedures/ resolve there).
# WHERE: central-command/scripts/, runnable by an agent in any checkout of any repo.
# HOW:   CENTRAL_COMMAND_READ_PAT=<read-only PAT> bash scripts/sync-central-policy.sh [--dry-run] [DEST]
#        --dry-run reports whether the folder is current (exit 0 current, 1 differs)
#        and writes nothing. DEST defaults to <repo-root>/central-command.
# Same pull as .github/workflows/central-policy-sync.yml: resolve dev to a sha, fetch
# THAT sha (immutable; a ref move mid-pull cannot tear the tree), extract with git
# archive. The PAT is read from the environment only, never argv (argv shows in `ps`).
# No submodules; a symlink resolving outside the extracted tree fails the sync.
# Test: run with --dry-run before and after a sync.
set -euo pipefail

DRY=0
DEST=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    *) DEST="$arg" ;;
  esac
done

PAT="${CENTRAL_COMMAND_READ_PAT:-}"
if [ -z "$PAT" ]; then
  echo "sync-central-policy: set CENTRAL_COMMAND_READ_PAT (read-only PAT for gitjfmd/central-command); never pass it in argv" >&2
  exit 2
fi

SRC_URL="https://github.com/gitjfmd/central-command.git"
# PAT travels in an auth header, never in the remote URL: git prints the URL on
# failure and would print the token with it.
AUTH="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$PAT" | base64 | tr -d '\n')"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DEST="${DEST:-$ROOT/central-command}"

SHA="$(git -c http.extraheader="$AUTH" ls-remote "$SRC_URL" refs/heads/dev | cut -f1)"
[ -n "$SHA" ] || { echo "sync-central-policy: cannot resolve central-command dev" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git -c http.extraheader="$AUTH" -C "$TMP" init -q
git -c http.extraheader="$AUTH" -C "$TMP" fetch --no-tags --depth=1 "$SRC_URL" "$SHA"
mkdir -p "$TMP/tree"
git -C "$TMP" archive FETCH_HEAD policies-procedures | tar -x -C "$TMP/tree"

# No symlink may resolve outside the extracted tree.
while IFS= read -r link; do
  target="$(readlink -f "$link")"
  case "$target" in
    "$TMP/tree"/*) ;;
    *)
      echo "sync-central-policy: symlink $link resolves outside the tree ($target); refusing" >&2
      exit 1
      ;;
  esac
done < <(find "$TMP/tree" -type l)

if [ "$DRY" = 1 ]; then
  if [ -d "$DEST/policies-procedures" ] && diff -r "$TMP/tree/policies-procedures" "$DEST/policies-procedures" >/dev/null 2>&1; then
    echo "sync-central-policy: current (central-command dev $SHA)"
    exit 0
  fi
  echo "sync-central-policy: DIFFERS (central-command dev $SHA; run without --dry-run to update)"
  exit 1
fi

rm -rf "$DEST/policies-procedures"
mkdir -p "$DEST"
mv "$TMP/tree/policies-procedures" "$DEST/policies-procedures"
echo "sync-central-policy: updated $DEST/policies-procedures (central-command dev $SHA)"
