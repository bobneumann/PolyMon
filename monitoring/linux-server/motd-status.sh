#!/bin/bash
# motd-status.sh — prints server health summary at SSH login
# Deploy to: /etc/profile.d/motd-status.sh

SERVICES=("postgresql")          # adjust to match health-check.sh
DISK_MOUNTS=("/")                # adjust to match health-check.sh
BACKUP_GLOB="/var/backups/db-backup-*.tar.gz"

# Color codes
RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'

status_color() {
    # usage: status_color "label" "ok|warn|fail" "detail"
    local label="$1" state="$2" detail="$3"
    case "$state" in
        ok)   printf "  ${GREEN}%-12s${NC} %s\n" "$label" "$detail" ;;
        warn) printf "  ${YELLOW}%-12s${NC} %s\n" "$label" "$detail" ;;
        fail) printf "  ${RED}%-12s${NC} %s\n" "$label" "$detail" ;;
    esac
}

echo ""
echo "══════════════════════════════════════════════════════"
printf "  %s   %s\n" "$(hostname -s)" "$(date)"
echo "══════════════════════════════════════════════════════"

# Uptime
printf "  %-12s %s\n" "Uptime" "$(uptime -p)"

# Disk
for mount in "${DISK_MOUNTS[@]}"; do
    pct=$(df --output=pcent "$mount" 2>/dev/null | tail -1 | tr -d ' %')
    free_gb=$(df --output=avail --block-size=1G "$mount" 2>/dev/null | tail -1 | tr -d ' ')
    [ -z "$pct" ] && continue
    if   [ "$pct" -ge 90 ]; then status_color "Disk $mount" "fail" "${pct}%  (${free_gb}GB free)"
    elif [ "$pct" -ge 80 ]; then status_color "Disk $mount" "warn" "${pct}%  (${free_gb}GB free)"
    else                         status_color "Disk $mount" "ok"   "${pct}%  (${free_gb}GB free)"
    fi
done

# Memory
total=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
used=$(awk '/^MemAvailable:/{avail=int($2/1024)} /^MemTotal:/{total=int($2/1024)} END{print total-avail}' /proc/meminfo)
pct=$(( used * 100 / total ))
if   [ "$pct" -ge 95 ]; then status_color "Memory" "fail" "${pct}%  (${used}MB / ${total}MB)"
elif [ "$pct" -ge 85 ]; then status_color "Memory" "warn" "${pct}%  (${used}MB / ${total}MB)"
else                         status_color "Memory" "ok"   "${pct}%  (${used}MB / ${total}MB)"
fi

# Load
load=$(awk '{print $1"  "$2"  "$3}' /proc/loadavg)
load5=$(awk '{print $2}' /proc/loadavg)
if   awk "BEGIN{exit !($load5 >= 8.0)}"; then status_color "Load" "fail" "$load  (1m 5m 15m)"
elif awk "BEGIN{exit !($load5 >= 4.0)}"; then status_color "Load" "warn" "$load  (1m 5m 15m)"
else                                          status_color "Load" "ok"   "$load  (1m 5m 15m)"
fi

# Services
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        status_color "$svc" "ok" "running"
    else
        status_color "$svc" "fail" "$(systemctl is-active "$svc" 2>/dev/null)"
    fi
done

# Backup age
if [ -n "$BACKUP_GLOB" ]; then
    latest=$(ls -t $BACKUP_GLOB 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        age_hours=$(( ($(date +%s) - $(stat -c %Y "$latest")) / 3600 ))
        if   [ "$age_hours" -ge 50 ]; then status_color "Backup" "fail" "${age_hours}h ago  ($(basename "$latest"))"
        elif [ "$age_hours" -ge 26 ]; then status_color "Backup" "warn" "${age_hours}h ago  ($(basename "$latest"))"
        else                               status_color "Backup" "ok"   "${age_hours}h ago  ($(basename "$latest"))"
        fi
    else
        status_color "Backup" "fail" "no backup files found"
    fi
fi

echo "══════════════════════════════════════════════════════"
echo ""
