# Get-MatrixRooms.ps1 — Lists all Matrix rooms with members, for finding bridged Signal room IDs
# Run standalone in PowerShell ISE or terminal
# Usage: .\Get-MatrixRooms.ps1
#        .\Get-MatrixRooms.ps1 -Filter "John"

param(
    [string]$Filter = ""
)

$BaseUrl     = "https://matrix.yourdomain.com"        # <-- Change to your Matrix homeserver URL
$MatrixToken = "your-access-token-here"               # <-- Matrix access token

$headers = @{ Authorization = "Bearer $MatrixToken" }

# Get all joined rooms
$rooms = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/v3/joined_rooms" -Headers $headers -TimeoutSec 15

foreach ($roomId in $rooms.joined_rooms) {
    $encodedRoom = [Uri]::EscapeDataString($roomId)

    # Get room display name
    try {
        $nameEvent = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/v3/rooms/$encodedRoom/state/m.room.name" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        $roomName = $nameEvent.name
    } catch {
        $roomName = "(no name)"
    }

    # Get room members
    $members = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/v3/rooms/$encodedRoom/members" -Headers $headers -TimeoutSec 10
    $memberList = $members.chunk | ForEach-Object {
        $_.state_key
    }

    # Get display names for signal bridge users
    $displayNames = @()
    foreach ($member in $memberList) {
        if ($member -like "@signal_*") {
            try {
                $profile = Invoke-RestMethod -Uri "$BaseUrl/_matrix/client/v3/profile/$([Uri]::EscapeDataString($member))/displayname" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                $displayNames += $profile.displayname
            } catch {
                $displayNames += $member
            }
        }
    }

    $info = [PSCustomObject]@{
        RoomID       = $roomId
        RoomName     = $roomName
        SignalUsers  = ($displayNames -join ", ")
        MemberCount  = $memberList.Count
    }

    # Apply filter if specified
    if ($Filter -eq "" -or $info.RoomName -match $Filter -or $info.SignalUsers -match $Filter -or $info.RoomID -match $Filter) {
        $info
    }
}
