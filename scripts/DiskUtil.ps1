<#
.SYNOPSIS
    Simple Disk Utility in PowerShell 5.1+
.DESCRIPTION
    Lists disk info, usage, health, and supports command-line flags.
#>

# --- Argument parsing ---
$flags = @{
    list = $false
    usage = $false
    health = $false
    help = $false
}

foreach ($arg in $args) {
    switch ($arg.ToLower()) {
        '--list' { $flags.list = $true }
        '-l'     { $flags.list = $true }
        '--usage' { $flags.usage = $true }
        '-u'     { $flags.usage = $true }
        '--health' { $flags.health = $true }
        '--help' { $flags.help = $true }
        '-h'     { $flags.help = $true }
    }
}

# --- Help Message ---
function Show-Help {
    Write-Output @"
DiskUtil.ps1 - Simple Disk Utility Tool

USAGE:
    .\DiskUtil.ps1 [options]

OPTIONS:
    --list, -l         List physical disks and partitions
    --usage, -u        Show disk space usage
    --health           Show basic disk health info
    --help, -h         Show this help message

EXAMPLES:
    .\DiskUtil.ps1 --list
    .\DiskUtil.ps1 --usage
"@
}

# --- Functions ---
function Show-DiskInfo {
    Get-PhysicalDisk | Format-Table -AutoSize
    Get-Disk | Format-Table -AutoSize
    Get-Partition | Format-Table -AutoSize
}

function Show-Usage {
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{L="Used(GB)";E={"{0:N2}" -f (($_.Used/1GB))}}, @{L="Free(GB)";E={"{0:N2}" -f (($_.Free/1GB))}}, @{L="Total(GB)";E={"{0:N2}" -f (($_.Used + $_.Free)/1GB)}}
}

function Show-Health {
    Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus, Size | Format-Table -AutoSize
}

# --- Execution ---
if ($flags.help -or $args.Count -eq 0) {
    Show-Help
    exit
}

if ($flags.list) { Show-DiskInfo }
if ($flags.usage) { Show-Usage }
if ($flags.health) { Show-Health }
