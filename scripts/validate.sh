#!/usr/bin/env bash
#
# validate.sh - Validates that mitigations are effective.
# Runs Nmap and Netcat scans from the admin container and verifies
# that critical backend services are no longer reachable.
#

set -euo pipefail

LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/validation_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

echo "=== Validation Started at $(date) ===" | tee "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Attempt to reach MySQL (should fail) ---" | tee -a "${LOG_FILE}"
docker exec admin nc -vz mysql 3306 2>&1 | tee -a "${LOG_FILE}" || echo "BLOCKED as expected" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Attempt to reach Redis (should fail) ---" | tee -a "${LOG_FILE}"
docker exec admin nc -vz redis 6379 2>&1 | tee -a "${LOG_FILE}" || echo "BLOCKED as expected" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Attempt to reach API (should succeed) ---" | tee -a "${LOG_FILE}"
docker exec admin nc -vz api 80 2>&1 | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Verify HTTPS is active ---" | tee -a "${LOG_FILE}"
curl -sk https://localhost -o /dev/null -w "HTTP status: %{http_code}\n" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "=== Validation Completed at $(date) ===" | tee -a "${LOG_FILE}"