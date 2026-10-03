#!/bin/sh
# Apply the Walkman patches to a Classipod checkout, on a new branch based
# on the upstream commit they were made against.
#
# Usage: classipod/apply.sh [path/to/Classipod]
set -eu

here=$(cd "$(dirname "$0")" && pwd)
repo=${1:-"$HOME/Developer/Classipod"}
base=$(cat "$here/upstream-commit")
branch=${BRANCH:-walkman-battery}

cd "$repo"
if [ -n "$(git status --porcelain)" ]; then
  echo "$repo has uncommitted changes. Commit or stash them first." >&2
  exit 1
fi
git fetch https://github.com/adeeteya/classipod.git "$base"
git switch -c "$branch" "$base"
git am -3 "$here"/patches/*.patch
echo "Patched Classipod is on branch $branch in $repo"
