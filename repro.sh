#!/usr/bin/env bash
# Shows --filter='[main...HEAD]' selecting a package that only changed on main
# after the branch point, when filterUsingTasks is on.
#
#   ./repro.sh              uses npx turbo@latest (shows the bug)
#   ./repro.sh /path/turbo  uses a given binary (a build of #13917 should pass)
set -u
cd "$(dirname "$0")"
TURBO=${1:-}
turbo() { if [ -n "$TURBO" ]; then "$TURBO" "$@"; else npx --yes turbo@latest "$@"; fi; }
g() { git -c user.email=a@b.c -c user.name=t "$@"; }

g checkout -q main
g branch -q -D my-branch 2>/dev/null
g reset -q --hard base

g checkout -q -b my-branch
echo "changed on branch" > apps/my-app/note.txt
g add -A && g commit -qm "change my-app on branch"

g checkout -q main
echo "changed on main" >> packages/util/index.js
g add -A && g commit -qm "change util on main"
g checkout -q my-branch

echo "my-app changed on my-branch. util changed on main, after the branch point."
echo
echo "git diff main...HEAD (merge base to head) touches:"
git diff --name-only main...HEAD | sed 's/^/  /'
echo
echo "git diff main..HEAD (tip to tip) touches:"
git diff --name-only main HEAD | sed 's/^/  /'
echo
echo "turbo run build --filter='[main...HEAD]' selects:"
turbo run build --filter='[main...HEAD]' --dry=json 2>/dev/null \
  | python3 -c "import json,sys; [print('  '+t['taskId']) for t in json.load(sys.stdin)['tasks']]"
echo
echo "  a three dot range means merge base to head, so only my-app#build"
echo "  belongs here. if util#build is listed, the range is being read as"
echo "  tip to tip, which is the bug."
