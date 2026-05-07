#!/bin/bash
# Post-deploy verification script
# Run on Target Node after deployment to confirm the app is healthy.

set -euo pipefail

HOST="${APP_HOST:-localhost}"
PORT="${APP_PORT:-80}"
BASE_URL="http://${HOST}:${PORT}"

PASS=0
FAIL=0

check() {
    local description="$1"
    local url="$2"
    local expected_status="$3"

    actual_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || echo "000")

    if [ "$actual_status" = "$expected_status" ]; then
        echo "  [OK] ${description} → ${actual_status}"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${description} → expected ${expected_status}, got ${actual_status}"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Verifying deployment at ${BASE_URL} ==="
echo ""

echo "-- Health checks --"
check "GET /health/alive" "${BASE_URL}/health/alive" "200"
check "GET /health/ready" "${BASE_URL}/health/ready" "200"

echo ""
echo "-- API endpoints --"
check "GET / (root)"        "${BASE_URL}/"       "200"
check "GET /items (JSON)"   "${BASE_URL}/items"  "200"

echo ""
echo "-- Docker container running --"
if docker ps --format '{{.Names}}' | grep -q "app"; then
    echo "  [OK] app container is running"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] app container is NOT running"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "-- Nginx container running --"
if docker ps --format '{{.Names}}' | grep -q "nginx"; then
    echo "  [OK] nginx container is running"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] nginx container is NOT running"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
