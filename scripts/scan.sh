#!/usr/bin/env bash
#
# scan.sh - Automated reconnaissance script for Activity 1
# Executes Nmap and Netcat scans from the admin container
# and saves the output to a timestamped log file.
#

set -euo pipefail

LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/scan_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

echo "=== Reconnaissance Scan Started at $(date) ===" | tee "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Nmap scan: nginx (port 80) ---" | tee -a "${LOG_FILE}"
docker exec admin nmap -sV nginx | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Nmap scan: mysql (port 3306) ---" | tee -a "${LOG_FILE}"
docker exec admin nmap -p 3306 mysql | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Nmap scan: redis (port 6379) ---" | tee -a "${LOG_FILE}"
docker exec admin nmap -p 6379 redis | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Netcat: api port 80 ---" | tee -a "${LOG_FILE}"
docker exec admin nc -vz api 80 2>&1 | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "--- Netcat: redis port 6379 ---" | tee -a "${LOG_FILE}"
docker exec admin nc -vz redis 6379 2>&1 | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

echo "=== Reconnaissance Scan Completed at $(date) ===" | tee -a "${LOG_FILE}"