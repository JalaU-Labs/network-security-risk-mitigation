#!/usr/bin/env bash
#
# firewall.sh - Example firewall rule for blocking Redis from external access.
# In Docker, effective isolation is achieved via network segmentation.
# This script documents the equivalent iptables rule for educational purposes.
#

set -euo pipefail

echo "Applying example iptables rule to block Redis port 6379 from external access..."
docker exec api iptables -A INPUT -p tcp --dport 6379 -j DROP || {
    echo "Note: iptables may not be available in the container. Network segmentation is the effective control."
    exit 0
}

echo "Rule applied successfully."