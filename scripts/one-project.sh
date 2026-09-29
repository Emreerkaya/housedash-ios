#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
quarantine="${HD_QUARANTINE:-$root/.hd-quarantine}"
project="$root/HouseDash.xcodeproj"

quarantineDuplicates() {
    local stage="$1"
    local moved=0
    local duplicate
    while IFS= read -r -d '' duplicate; do
        mkdir -p "$quarantine/$stage"
        local landing
        landing="$quarantine/$stage/$(printf '%s' "${duplicate#"$root/"}" | tr '/ ' '__')"
        mv "$duplicate" "$landing"
        printf 'quarantined %s to %s\n' "$duplicate" "$landing" >&2
        moved=$((moved + 1))
    done < <(find "$root" -name '* [0-9]*' -not -path "$root/.git/*" -not -path "$quarantine/*" -print0)
    printf 'the %s sweep quarantined %s duplicate path(s)\n' "$stage" "$moved" >&2
}

countProjects() {
    find "$root" -name '*.xcodeproj' -not -path "$root/.git/*" -not -path "$quarantine/*" -prune -print
}

quarantineDuplicates before-generate
rm -rf "$project"
xcodegen generate --spec "$root/project.yml" --project "$root"
quarantineDuplicates after-generate

projects="$(countProjects)"
count="$(printf '%s\n' "$projects" | grep -c . || true)"
if [ "$count" -ne 1 ]; then
    printf '%s\n' "$projects" >&2
    printf 'the tree holds %s .xcodeproj bundles and a build is only unambiguous with one; xcodebuild only refuses the ambiguity it can see from its own invocation directory, so a copy one directory down builds green and silently\n' \
        "$count" >&2
    exit 78
fi
if [ "$projects" != "$project" ]; then
    printf 'the one project in the tree is %s and the schemes are declared on %s\n' "$projects" "$project" >&2
    exit 78
fi
printf 'one project at %s, and no duplicate path anywhere under %s\n' "$project" "$root"
