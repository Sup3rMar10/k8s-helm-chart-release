#!/usr/bin/env bash
# values.schema.json should reject bad values at `helm template` / `helm install` time,
# before anything reaches a cluster. Each case below must fail; the last one must pass.
set -uo pipefail

chart="$(cd "$(dirname "$0")/.." && pwd)/charts/webapp"
pass=0
fail=0

must_fail() { # must_fail <description> <helm --set args...>
  local desc="$1"
  shift
  if helm template t "$chart" "$@" >/dev/null 2>&1; then
    echo "  FAIL  accepted: $desc"
    fail=$((fail + 1))
  else
    echo "  PASS  rejected: $desc"
    pass=$((pass + 1))
  fi
}

must_pass() {
  local desc="$1"
  shift
  if helm template t "$chart" "$@" >/dev/null 2>&1; then
    echo "  PASS  accepted: $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL  rejected: $desc"
    fail=$((fail + 1))
  fi
}

must_fail "replicaCount=0" --set replicaCount=0
must_fail "replicaCount=100" --set replicaCount=100
must_fail "replicaCount as a string" --set-string replicaCount=two
must_fail "pullPolicy=Sometimes" --set image.pullPolicy=Sometimes
must_fail "service.port=70000" --set service.port=70000
must_fail "service.type=ExternalName" --set service.type=ExternalName
must_pass "a valid combination" --set replicaCount=3 --set image.pullPolicy=Always --set service.port=8080

echo
echo "schema checks passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
