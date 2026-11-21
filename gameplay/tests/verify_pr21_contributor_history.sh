#!/usr/bin/env bash
# Read-only contributor ancestry audit: no rebase, squash, cherry-pick, or force push.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ref=HEAD
if test $# -gt 0; then ref="$1"; fi
git rev-parse --verify "$ref^{commit}" >/dev/null

for pair in "Ethan:3ddaf72" "Austin:a9b7827" \
 "Eva:ed94c21" "Eva:f3da066" "Eva:6681c63" \
 "Jackson:a8d8cd6" "Jackson:b7dec54" \
 "Angela:e7f142e" "Angela:55fe753" "Suwen_Garden:ca345d6"; do
  owner="$(printf '%s' "$pair" | cut -d: -f1)"
  sha="$(printf '%s' "$pair" | cut -d: -f2)"
  if ! git merge-base --is-ancestor "$sha" "$ref"; then
    echo "FAIL missing original $owner commit $sha from $ref" >&2
    exit 2
  fi
  printf 'PRESERVED original %-15s %s %s\n' "$owner" \
    "$(git rev-parse --short "$sha")" "$(git show -s --format='%an <%ae>' "$sha")"
done

# Exact, native two-parent merge: second parent is teammate original SHA.
for pair in "Main_with_Ethan:c5134b0:29ff3df" \
 "Austin:5df9c35:a9b7827" "Eva:3051452:f3da066" \
 "Jackson:c382178:b7dec54" "Angela:086c6fb:55fe753"; do
  IFS=: read -r label merge source <<< "$pair"
  if ! git merge-base --is-ancestor "$merge" "$ref"; then
    echo "FAIL missing $merge" >&2
    exit 3
  fi
  read -r commit parent1 parent2 extra < <(git rev-list --parents -n 1 "$merge")
  if test -z "$parent2" || test -n "$extra" ||
     test "$(git rev-parse "$parent2")" != "$(git rev-parse "$source")"; then
    echo "FAIL $label native merge history lost" >&2
    exit 4
  fi
  echo "PRESERVED MERGE $label $merge -> parents $parent1 $parent2"
done
if git ls-tree -r --name-only "$ref" | grep -Eq \
  '^gameplay/(observatory|experimental/minimal_arena)/'; then
  echo "FAIL unapproved arena in deliverable" >&2
  exit 5
fi
echo "PR21_CONTRIBUTOR_HISTORY_PASS originals=10 true_merges=5"
