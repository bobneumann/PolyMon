#Requires -Version 5.0
<#
.SYNOPSIS
    PolyMon PowerShell monitor for SNMP GET queries.

.DESCRIPTION
    Queries a single OID via SNMPv2c and reports OK/Warn/Error.
    Optionally applies numeric thresholds and records the value as a counter.

.REQUIREMENT
    Install-Module -Name Indented.Net.Snmp -Scope AllUsers

.USAGE
    Paste this script into a PolyMon PowerShell monitor definition.
    Edit the variables in the CONFIGURATION block below.
    To monitor multiple OIDs, clone and add another PowerShell monitor.
#>

# ── CONFIGURATION ────────────────────────────────────────────────────────────

$Target     = '192.168.1.1'    # IP or hostname of SNMP device
$Community  = 'public'         # SNMPv2c community string
$OID        = '1.3.6.1.2.1.1.1.0'  # OID to query (default: sysDescr)

# Numeric thresholds — set to -1 to disable
# If the OID value is numeric, alert when it exceeds these values
$WarnAbove  = -1   # e.g. 80 to warn above 80
$ErrorAbove = -1   # e.g. 95 to error above 95

# Set to $true to record the OID value as a PolyMon counter (numeric OIDs only)
$RecordCounter = $false
$CounterName   = 'SNMP value'

# ── END CONFIGURATION ─────────────────────────────────────────────────────────

if (-not (Get-Module -ListAvailable -Name 'Indented.Net.Snmp')) {
    $Status.StatusID   = 3
    $Status.StatusText = 'Module not installed. Run: Install-Module -Name Indented.Net.Snmp -Scope AllUsers'
    return
}

Import-Module Indented.Net.Snmp -ErrorAction Stop

try {
    $result = Get-SnmpData -ComputerName $Target -Community $Community -OID $OID -Version '2c' -ErrorAction Stop
} catch {
    $Status.StatusID   = 3
    $Status.StatusText = "SNMP error querying ${Target}: $_"
    return
}

if ($null -eq $result -or $null -eq $result.Value) {
    $Status.StatusID   = 3
    $Status.StatusText = "No response from ${Target} OID ${OID}"
    return
}

$value = [string]$result.Value
$Status.StatusID   = 1
$Status.StatusText = "${Target} [${OID}] = ${value}"

# Numeric threshold checks
if ($WarnAbove -ge 0 -or $ErrorAbove -ge 0) {
    $numeric = 0.0
    if ([double]::TryParse($value, [ref]$numeric)) {
        if ($ErrorAbove -ge 0 -and $numeric -gt $ErrorAbove) {
            $Status.StatusID   = 3
            $Status.StatusText = "${Status.StatusText} (exceeds error threshold ${ErrorAbove})"
        } elseif ($WarnAbove -ge 0 -and $numeric -gt $WarnAbove) {
            $Status.StatusID   = 2
            $Status.StatusText = "${Status.StatusText} (exceeds warning threshold ${WarnAbove})"
        }
    }
}

# Record counter
if ($RecordCounter -and $Counters) {
    $numeric = 0.0
    if ([double]::TryParse($value, [ref]$numeric)) {
        $Counters.Add($CounterName, $numeric)
    }
}
