#!/usr/bin/env bash
# Recreate signoff-studio-support with a single commit — no Co-authored-by trailers.
# Requires: Git for Windows, gh CLI logged in with repo + delete_repo scopes.
set -euo pipefail

REPO="samuccaya/signoff-studio-support"
GIT="/c/Program Files/Git/mingw64/libexec/git-core/git.exe"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

export GIT_AUTHOR_NAME="dnatranjan"
export GIT_AUTHOR_EMAIL="samuccaya@gmail.com"
export GIT_COMMITTER_NAME="dnatranjan"
export GIT_COMMITTER_EMAIL="samuccaya@gmail.com"

cd "$ROOT"

echo "==> Deleting remote repo (if it exists)..."
if gh repo view "$REPO" >/dev/null 2>&1; then
  gh repo delete "$REPO" --yes
fi

echo "==> Creating fresh public repo..."
gh repo create "$REPO" \
  --public \
  --description "Public bug reports and discussions for Signoff Studio" \
  --enable-issues

gh api -X PATCH "repos/$REPO" -f has_discussions=true >/dev/null

echo "==> Building orphan commit with git commit-tree..."
rm -rf .git
"$GIT" init -b master
"$GIT" add README.md .github/

TREE=$("$GIT" write-tree)
COMMIT=$("$GIT" commit-tree "$TREE" -m "Initial public support repo for Signoff Studio issues and discussions.")
"$GIT" update-ref refs/heads/master "$COMMIT"
"$GIT" remote add origin "https://github.com/$REPO.git"
"$GIT" push -u origin master

echo "==> Verifying commit (must show only dnatranjan, no trailers)..."
"$GIT" log -1 --format=full

echo "==> Creating labels..."
labels=(
  "customer-reported|E8F5E9"
  "impact:blocking|B60205"
  "impact:slowing|D93F0B"
  "impact:annoying|FBCA04"
  "impact:regression|5319E7"
  "area:api|1D76DB"
  "area:runner|0E8A16"
  "area:database|006B75"
  "area:scripting|F9D0C4"
  "area:import-export|C5DEF5"
  "area:installer|BFDADC"
  "area:vscode|7057FF"
  "area:other|EDEDED"
  "surface:desktop|0075CA"
  "surface:vscode|007ACC"
  "surface:browser|FF6B6B"
)

for entry in "${labels[@]}"; do
  name="${entry%%|*}"
  color="${entry##*|}"
  gh api -X POST "repos/$REPO/labels" -f name="$name" -f color="$color" >/dev/null 2>&1 || true
done

echo "==> Contributors (API):"
gh api "repos/$REPO/contributors" --jq '.[].login'

echo "Done. Open https://github.com/$REPO and confirm only samuccaya appears under Contributors."
