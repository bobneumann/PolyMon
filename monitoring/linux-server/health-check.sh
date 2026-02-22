#!/bin/bash
# health-check.sh — Linux server monitoring with email alerts
# Runs via cron every 5 minutes
# Sends email on state transitions (OK→WARN/CRIT and WARN/CRIT→OK) — no repeat spam

# ── Configuration ─────────────────────────────────────────────────────────────
ALERT_TO="alerts@example.com"           # where to send alerts
ALERT_FROM="dbserver@example.com"       # from address (must be accepted by relay)
HOST_LABEL="$(hostname -s)"             # used in subject lines
STATE_DIR="/var/lib/health-check"       # persists alert states across runs

# Thresholds
DISK_WARN=80    # %
DISK_CRIT=90    # %
MEM_WARN=85     # %
MEM_CRIT=95     # %
LOAD_WARN=4.0   # 5-min load average (tune to your CPU count; rough guide: warn at 2x cores)
LOAD_CRIT=8.0
BACKUP_WARN=26  # hours since last backup before warning
BACKUP_CRIT=50  # hours since last backup before critical

# Filesystem mounts to check (skip the rest)
DISK_MOUNTS=("/")

# Backup file glob — set to "" to skip backup age check
BACKUP_GLOB="/var/backups/db-backup-*.tar.gz"

# systemd services to check — set to () to skip
SERVICES=("postgresql")

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "$STATE_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────
send_email() {
    local subject="$1"
    local body="$2"
    printf "To: %s\nFrom: %s\nSubject: %s\n\n%s\n" \
        "$ALERT_TO" "$ALERT_FROM" "$subject" "$body" \
        | msmtp "$ALERT_TO"
}

# Returns 0 (true) if state changed, writes new state. Suppresses alert if new state is OK with no previous state.
state_changed() {
    local key="$1"
    local new_state="$2"
    local state_file="$STATE_DIR/$key"
    local prev_state
    prev_state=$(cat "$state_file" 2>/dev/null || echo "OK")

    if [ "$new_state" != "$prev_state" ]; then
        echo "$new_state" > "$state_file"
        # Don't fire a "recovered to OK" alert if we never sent a bad-state alert
        [ "$new_state" = "OK" ] && [ "$prev_state" = "OK" ] && return 1
        return 0
    fi
    return 1
}

# ── Checks ────────────────────────────────────────────────────────────────────
check_disk() {
    for mount in "${DISK_MOUNTS[@]}"; do
        local pct
        pct=$(df --output=pcent "$mount" 2>/dev/null | tail -1 | tr -d ' %')
        [ -z "$pct" ] && continue

        local key="disk_$(echo "$mount" | tr '/' '_' | tr -s '_')"
        local free_gb
        free_gb=$(df --output=avail --block-size=1G "$mount" 2>/dev/null | tail -1 | tr -d ' ')

        if [ "$pct" -ge "$DISK_CRIT" ]; then
            if state_changed "$key" "CRIT"; then
                send_email "[$HOST_LABEL] CRITICAL: Disk $mount at ${pct}%" \
"Disk usage on $mount has reached ${pct}% (${free_gb}GB free).
Critical threshold: ${DISK_CRIT}%

Server: $HOST_LABEL
Time:   $(date)"
            fi
        elif [ "$pct" -ge "$DISK_WARN" ]; then
            if state_changed "$key" "WARN"; then
                send_email "[$HOST_LABEL] WARNING: Disk $mount at ${pct}%" \
"Disk usage on $mount has reached ${pct}% (${free_gb}GB free).
Warning threshold: ${DISK_WARN}%

Server: $HOST_LABEL
Time:   $(date)"
            fi
        else
            if state_changed "$key" "OK"; then
                send_email "[$HOST_LABEL] RECOVERED: Disk $mount now at ${pct}%" \
"Disk usage on $mount has recovered to ${pct}% (${free_gb}GB free).

Server: $HOST_LABEL
Time:   $(date)"
            fi
        fi
    done
}

check_memory() {
    local total used pct
    total=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
    used=$(awk '/^MemAvailable:/{avail=int($2/1024)} /^MemTotal:/{total=int($2/1024)} END{print total-avail}' /proc/meminfo)
    pct=$(( used * 100 / total ))

    if [ "$pct" -ge "$MEM_CRIT" ]; then
        if state_changed "memory" "CRIT"; then
            send_email "[$HOST_LABEL] CRITICAL: Memory at ${pct}%" \
"Memory usage has reached ${pct}% (${used}MB used of ${total}MB).
Critical threshold: ${MEM_CRIT}%

Server: $HOST_LABEL
Time:   $(date)

Top consumers:
$(ps aux --sort=-%mem | awk 'NR<=6{printf \"%-10s %5s%%  %s\\n\", $1, $4, $11}')"
        fi
    elif [ "$pct" -ge "$MEM_WARN" ]; then
        if state_changed "memory" "WARN"; then
            send_email "[$HOST_LABEL] WARNING: Memory at ${pct}%" \
"Memory usage has reached ${pct}% (${used}MB used of ${total}MB).
Warning threshold: ${MEM_WARN}%

Server: $HOST_LABEL
Time:   $(date)"
        fi
    else
        if state_changed "memory" "OK"; then
            send_email "[$HOST_LABEL] RECOVERED: Memory now at ${pct}%" \
"Memory usage has recovered to ${pct}% (${used}MB used of ${total}MB).

Server: $HOST_LABEL
Time:   $(date)"
        fi
    fi
}

check_load() {
    local load
    load=$(awk '{print $2}' /proc/loadavg)  # 5-minute average

    if awk "BEGIN{exit !($load >= $LOAD_CRIT)}"; then
        if state_changed "load" "CRIT"; then
            send_email "[$HOST_LABEL] CRITICAL: Load average ${load}" \
"5-minute load average is ${load} (critical threshold: ${LOAD_CRIT}).

Server: $HOST_LABEL
Time:   $(date)

Top CPU consumers:
$(ps aux --sort=-%cpu | awk 'NR<=6{printf \"%-10s %5s%%  %s\\n\", $1, $3, $11}')"
        fi
    elif awk "BEGIN{exit !($load >= $LOAD_WARN)}"; then
        if state_changed "load" "WARN"; then
            send_email "[$HOST_LABEL] WARNING: Load average ${load}" \
"5-minute load average is ${load} (warning threshold: ${LOAD_WARN}).

Server: $HOST_LABEL
Time:   $(date)"
        fi
    else
        if state_changed "load" "OK"; then
            send_email "[$HOST_LABEL] RECOVERED: Load average now ${load}" \
"Load average has recovered to ${load}.

Server: $HOST_LABEL
Time:   $(date)"
        fi
    fi
}

check_services() {
    for svc in "${SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
            if state_changed "svc_${svc}" "FAIL"; then
                send_email "[$HOST_LABEL] CRITICAL: Service '$svc' is DOWN" \
"Service '$svc' is not running.

Server: $HOST_LABEL
Time:   $(date)

systemctl status:
$(systemctl status "$svc" 2>&1 | head -25)"
            fi
        else
            if state_changed "svc_${svc}" "OK"; then
                send_email "[$HOST_LABEL] RECOVERED: Service '$svc' is running" \
"Service '$svc' has recovered and is now active.

Server: $HOST_LABEL
Time:   $(date)"
            fi
        fi
    done
}

check_backup_age() {
    [ -z "$BACKUP_GLOB" ] && return

    local latest
    latest=$(ls -t $BACKUP_GLOB 2>/dev/null | head -1)

    if [ -z "$latest" ]; then
        if state_changed "backup" "MISSING"; then
            send_email "[$HOST_LABEL] CRITICAL: No backup files found" \
"No backup files matching '$BACKUP_GLOB' were found.

Server: $HOST_LABEL
Time:   $(date)"
        fi
        return
    fi

    local backup_epoch now_epoch age_hours
    backup_epoch=$(stat -c %Y "$latest")
    now_epoch=$(date +%s)
    age_hours=$(( (now_epoch - backup_epoch) / 3600 ))

    if [ "$age_hours" -ge "$BACKUP_CRIT" ]; then
        if state_changed "backup" "CRIT"; then
            send_email "[$HOST_LABEL] CRITICAL: Backup is ${age_hours}h old" \
"Last backup was ${age_hours} hours ago (critical threshold: ${BACKUP_CRIT}h).
Last backup: $(basename "$latest")

Server: $HOST_LABEL
Time:   $(date)"
        fi
    elif [ "$age_hours" -ge "$BACKUP_WARN" ]; then
        if state_changed "backup" "WARN"; then
            send_email "[$HOST_LABEL] WARNING: Backup is ${age_hours}h old" \
"Last backup was ${age_hours} hours ago (warning threshold: ${BACKUP_WARN}h).
Last backup: $(basename "$latest")

Server: $HOST_LABEL
Time:   $(date)"
        fi
    else
        state_changed "backup" "OK"
    fi
}

# ── Run all checks ────────────────────────────────────────────────────────────
check_disk
check_memory
check_load
check_services
check_backup_age
