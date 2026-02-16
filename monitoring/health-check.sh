#!/bin/bash
# health-check.sh — Writes system health JSON for Caddy to serve
# Runs via cron every 5 minutes: */5 * * * * /home/ubuntu/health-check.sh

OUTPUT="/var/www/health/health.json"

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Disk usage for root filesystem
DISK_PCT=$(df / --output=pcent | tail -1 | tr -d ' %')
DISK_FREE_GB=$(df / --output=avail --block-size=1G | tail -1 | tr -d ' ')

# Docker container status
CONDUIT_STATUS=$(docker inspect -f '{{.State.Status}}' conduit 2>/dev/null || echo "not_found")
SIGNAL_STATUS=$(docker inspect -f '{{.State.Status}}' mautrix-signal 2>/dev/null || echo "not_found")

# System uptime in hours
UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)
UPTIME_HOURS=$((UPTIME_SECONDS / 3600))

# Last backup age in hours
LATEST_BACKUP=$(ls -t /home/ubuntu/backups/matrix-backup-*.tar.gz 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_EPOCH=$(stat -c %Y "$LATEST_BACKUP")
    NOW_EPOCH=$(date +%s)
    BACKUP_AGE_HOURS=$(( (NOW_EPOCH - BACKUP_EPOCH) / 3600 ))
else
    BACKUP_AGE_HOURS=-1
fi

# Write JSON
cat > "$OUTPUT" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "disk_pct": $DISK_PCT,
  "disk_free_gb": $DISK_FREE_GB,
  "containers": {"conduit": "$CONDUIT_STATUS", "mautrix-signal": "$SIGNAL_STATUS"},
  "uptime_hours": $UPTIME_HOURS,
  "last_backup_age_hours": $BACKUP_AGE_HOURS
}
EOF
