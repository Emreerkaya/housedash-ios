#!/usr/bin/env bash
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
gate="${here}/agent-review.sh"
stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT

cat > "${stub_dir}/gh" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "diff" ]; then
    if [ -n "${STUB_FAIL_DIFF-}" ]; then
        printf 'gh: could not determine the changed files\n' >&2
        exit 1
    fi
    printf '%s' "${STUB_CHANGED-}"
    [ -n "${STUB_CHANGED-}" ] && printf '\n'
    exit 0
fi
if [ "${1:-}" = "api" ] && [ "${2:-}" = "graphql" ]; then
    if printf '%s' "$*" | grep -q reviewThreads; then
        printf '[{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":%s}}}}}]' "${STUB_THREADS:-[]}"
    else
        printf '[{"data":{"repository":{"pullRequest":{"reviews":{"nodes":%s}}}}}]' "${STUB_REVIEWS:-[]}"
    fi
    exit 0
fi
printf 'stub gh received an unexpected call: %s\n' "$*" >&2
exit 90
STUB
chmod +x "${stub_dir}/gh"

sha=1111111111111111111111111111111111111111
other=2222222222222222222222222222222222222222
touched_domain='Packages/Features/Sources/Features/Intake/Domain/DescriptionFilter.swift'
untouched='README.md'

review() {
    local dimension=$1 verdict=$2 at=${3:-$sha} push=${4:-true} assoc=${5:-OWNER} tail=${6:-} state=${7:-COMMENTED} typename=${8:-User}
    local body="Some prose about the change.\n\n<!-- review-sha: ${at} dimension: ${dimension} verdict: ${verdict} -->"
    [ -n "$tail" ] && body="${body}\n\n${tail}"
    printf '{"state":"%s","authorAssociation":"%s","authorCanPushToRepository":%s,"author":{"login":"someone","__typename":"%s"},"body":"%s"}' \
        "$state" "$assoc" "$push" "$typename" "$body"
}

review_as() {
    local state=$1 typename=$2 dimension=$3 verdict=$4
    review "$dimension" "$verdict" "$sha" true OWNER "" "$state" "$typename"
}

set_of() { printf '[%s]' "$(printf '%s,' "$@" | sed 's/,$//')"; }

all_five=$(set_of \
    "$(review accessibility clean)" \
    "$(review architecture clean)" \
    "$(review testing clean)" \
    "$(review security clean)")

pass=0
fail=0

check() {
    local name=$1 want=$2 changed=$3 reviews=$4 wanted_text=${5:-}
    local out got
    out=$(PATH="${stub_dir}:${PATH}" \
        STUB_CHANGED="$changed" STUB_REVIEWS="$reviews" STUB_THREADS='[]' \
        PR_NUMBER=1 HEAD_SHA="$sha" GITHUB_REPOSITORY=Emreerkaya/housedash-ios \
        bash "$gate" 2>&1)
    got=$?
    if [ "$got" -ne "$want" ]; then
        printf 'FAIL %s: expected exit %s, got %s\n%s\n\n' "$name" "$want" "$got" "$out" >&2
        fail=$((fail + 1))
        return
    fi
    if [ -n "$wanted_text" ] && ! printf '%s' "$out" | grep -q "$wanted_text"; then
        printf 'FAIL %s: exit %s was right but the message never said %s\n%s\n\n' "$name" "$got" "$wanted_text" "$out" >&2
        fail=$((fail + 1))
        return
    fi
    printf 'ok %s\n' "$name"
    pass=$((pass + 1))
}

check 'four clean reviews on a domain diff pass' 0 "$touched_domain" "$all_five" 'none blocked'

check 'three clean reviews pass when the diff avoids every trust-bearing path' 0 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'accessibility architecture testing'

check 'a domain diff without a security review is blocked' 1 "$touched_domain" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no security review'

check 'a missing accessibility review blocks' 1 "$untouched" \
    "$(set_of "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'a blocked verdict blocks' 1 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture blocked)" "$(review testing clean)")" \
    'reports verdict blocked'

check 'a verdict misspelled by one character fails closed rather than reading as clean' 1 "$untouched" \
    "$(set_of "$(review accessibility cleann)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not one of the verdicts'

check 'a review at a stale sha does not count' 1 "$untouched" \
    "$(set_of "$(review accessibility clean "$other")" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'a review by an author who cannot push is ignored' 1 "$untouched" \
    "$(set_of "$(review accessibility clean "$sha" false)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not entitled to gate a merge'

check 'a review by a drive-by contributor is ignored' 1 "$untouched" \
    "$(set_of "$(review accessibility clean "$sha" true CONTRIBUTOR)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not entitled to gate a merge'

check 'a trailer that is not the last line does not count' 1 "$untouched" \
    "$(set_of "$(review accessibility clean "$sha" true OWNER 'and one more thought afterwards')" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'a trailer naming only a sha prefix does not count' 1 "$untouched" \
    "$(set_of "$(review accessibility clean 1111111)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'a path git quotes still requires the security review' 1 \
    '"Packages/Features/Sources/Features/Intake/Domain/Gr\303\266\303\237e.swift"' \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no security review'

check 'a diff of the gate itself requires the security review' 1 \
    'scripts/agent-review.sh' \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no security review'

check 'a diff of the workflows requires the security review' 1 \
    '.github/workflows/process-review.yml' \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no security review'

check 'a clean review naming a dimension this diff does not require is not counted' 0 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)" "$(review invariants clean)")" \
    'is not counted'

check 'a blocked review blocks even when this diff does not require its dimension' 1 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)" "$(review security blocked)")" \
    'reports verdict blocked'

check 'a malformed verdict fails closed even on a dimension this diff does not require' 1 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)" "$(review security blockedd)")" \
    'is not one of the verdicts'

check 'a CHANGES_REQUESTED review carrying blocked still blocks' 1 "$untouched" \
    "$(set_of "$(review_as CHANGES_REQUESTED User accessibility blocked)" "$(review architecture clean)" "$(review testing clean)")" \
    'reports verdict blocked'

check 'a DISMISSED review does not count' 1 "$untouched" \
    "$(set_of "$(review_as DISMISSED User accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not entitled to gate a merge'

check 'a review by a bot does not count' 1 "$untouched" \
    "$(set_of "$(review_as COMMENTED Bot accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not entitled to gate a merge'

check 'a later clean review does not clear an earlier blocked one at the same sha' 1 "$untouched" \
    "$(set_of "$(review accessibility blocked)" "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'reports verdict blocked'

check 'a capitalised verdict is malformed rather than invisible' 1 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)" "$(review security Blocked)")" \
    'is not one of the verdicts'

check 'a capitalised blocked beside a clean one on the same required dimension still fails' 1 "$untouched" \
    "$(set_of "$(review accessibility BLOCKED)" "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'is not one of the verdicts'

check 'a verdict with trailing punctuation is malformed rather than invisible' 1 "$untouched" \
    "$(set_of "$(review accessibility clean)" "$(review architecture clean)" "$(review testing clean)" "$(review security 'blocked.')")" \
    'is not one of the verdicts'

check 'a misspelled dimension is noted and not counted rather than blocking' 1 "$untouched" \
    "$(set_of "$(review accessibilty clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'a dimension holding a regex metacharacter reads as missing, it does not satisfy the real one' 1 "$untouched" \
    "$(set_of "$(review 'a.cessibility' clean)" "$(review architecture clean)" "$(review testing clean)")" \
    'missing: no accessibility review'

check 'an empty diff refuses to pass vacuously' 2 "" "$all_five" 'refusing to pass vacuously'

check 'a body with CRLF line endings still counts, as the web UI sends them' 0 "$untouched" \
    "$(printf '[%s,%s,%s]' \
        "$(printf '{"state":"COMMENTED","authorAssociation":"OWNER","authorCanPushToRepository":true,"author":{"login":"someone","__typename":"User"},"body":"Prose.\\r\\n\\r\\n<!-- review-sha: %s dimension: accessibility verdict: clean -->\\r\\n"}' "$sha")" \
        "$(review architecture clean)" "$(review testing clean)")" \
    'none blocked'

check 'no reviews at all blocks' 1 "$untouched" '[]' 'missing: no accessibility review'

out=$(PATH="${stub_dir}:${PATH}" \
    STUB_CHANGED="$untouched" STUB_REVIEWS="$all_five" STUB_THREADS='[]' STUB_FAIL_DIFF=1 \
    PR_NUMBER=1 HEAD_SHA="$sha" GITHUB_REPOSITORY=Emreerkaya/housedash-ios \
    bash "$gate" 2>&1)
got=$?
if [ "$got" -ne 1 ] || printf '%s' "$out" | grep -qE 'every required dimension|refusing to pass vacuously'; then
    printf 'FAIL a gh that cannot list the changed files must fail loudly, not vacuously: exit %s\n%s\n\n' "$got" "$out" >&2
    fail=$((fail + 1))
else
    printf 'ok a gh that cannot list the changed files must fail loudly, not vacuously\n'
    pass=$((pass + 1))
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
