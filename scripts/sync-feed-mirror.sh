#!/bin/bash

# Copy the published update feeds to the old-feed mirror.
#
# Builds <= 0.7.5 read their Sparkle feed from https://dinhanhthi.github.io/SegDown/appcast.xml,
# and their Firefox add-ons read https://dinhanhthi.github.io/SegDown/firefox-updates.json.
# After the repo moved to Coprimal/SegDown, GitHub no longer serves or redirects those
# addresses, so the user site dinhanhthi/dinhanhthi.github.io serves a copy of both files
# under SegDown/. publish-appcast.sh runs this script on every release so those builds always
# see the latest version. Never edit the mirror's files by hand.
#
# It publishes the files as they are on origin/main (what the Pages workflow deploys), never
# the working tree, so a local edit can never reach the old feeds.
#
# Usage: scripts/sync-feed-mirror.sh

set -euo pipefail

MIRROR_REPO="dinhanhthi/dinhanhthi.github.io"
MIRROR_DIR="SegDown"
FILES=(appcast.xml firefox-updates.json)

fail() {
  echo "error: $*" >&2
  exit 1
}

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git fetch -q origin main || fail "git fetch origin main failed"
REF="origin/main"

version="$(git show "$REF:appcast.xml" | grep -o '<sparkle:shortVersionString>[^<]*' | head -1 | sed 's/.*>//' || true)"

for file in "${FILES[@]}"; do
  path="$MIRROR_DIR/$file"
  local_sha="$(git rev-parse --verify -q "$REF:$file")" || fail "$file not found on $REF"
  case "$file" in
    *.xml) git show "$REF:$file" | xmllint --noout - || fail "$file on $REF is not valid XML" ;;
    *.json) git show "$REF:$file" | jq -e . >/dev/null || fail "$file on $REF is not valid JSON" ;;
  esac

  current_sha="$(gh api "repos/$MIRROR_REPO/contents/$path" --jq .sha)" ||
    fail "cannot read $path in $MIRROR_REPO"
  [[ -n "$current_sha" ]] || fail "no sha for $path in $MIRROR_REPO"

  if [[ "$current_sha" == "$local_sha" ]]; then
    echo "mirror already current ($MIRROR_REPO/$path)"
    continue
  fi

  # The body goes through stdin: the base64 appcast grows with every release.
  git show "$REF:$file" | base64 | tr -d '\n' |
    jq -Rs --arg message "chore: sync SegDown $file ${version:-update}" --arg sha "$current_sha" \
      '{message: $message, content: ., sha: $sha}' |
    gh api -X PUT "repos/$MIRROR_REPO/contents/$path" --input - --jq .commit.sha >/dev/null ||
    fail "cannot update $path in $MIRROR_REPO"

  echo "mirror updated: https://dinhanhthi.github.io/$path (${version:-unknown version})"
done
