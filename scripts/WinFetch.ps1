# Get-NeofetchLikeInfo.ps1

function Get-WinFetch {
    # Get basic system info
    $computerInfo = Get-ComputerInfo
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $gpuInfo = Get-CimInstance -ClassName Win32_VideoController
    $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} # Fixed disks

    # ASCII Art (simple example)
    $asciiArt = @'
    _ _
   | (_)
   | |_ _ __ ___   ___  ___
   | | | '_ ` _ \ / _ \/ __|
   | | | | | | | |  __/\__ \
   |_|_|_| |_| |_|\___||___/
   Windows Fetch
'@

    Write-Host "$asciiArt" -ForegroundColor Cyan

    Write-Host "------------------------------------"
    Write-Host "OS:          $($computerInfo.WindowsProductName) $($computerInfo.OsVersion) ($($computerInfo.OsBuildNumber).$($computerInfo.OsUbr))"
    Write-Host "Host:        $($computerInfo.CsName)"
    Write-Host "Kernel:      $($osInfo.Version)"
    Write-Host "Uptime:      $((New-TimeSpan -Start $osInfo.LastBootUpTime -End (Get-Date)).ToString("dd\:hh\:mm\:ss"))"
    Write-Host "CPU:         $($cpuInfo.Name) ($($cpuInfo.NumberOfCores) Cores, $($cpuInfo.NumberOfLogicalProcessors) Threads)"
    Write-Host "GPU:         $($gpuInfo.Name)"
    Write-Host "RAM:         $("{0:N2} GB" -f ($computerInfo.CsTotalPhysicalMemory / 1GB))"
    Write-Host "Disk:        $("{0:N2} GB" -f ($diskInfo | Measure-Object -Property Size -Sum).Sum / 1GB) (Total)"
    Write-Host "BIOS:        $($computerInfo.BiosManufacturer) $($computerInfo.BiosVersion)"
    Write-Host "User:        $($env:USERNAME)@$($env:COMPUTERNAME)"
    Write-Host "Shell:       $($env:PSVersionTable.PSVersion.Major).$($env:PSVersionTable.PSVersion.Minor) Powershell"
    Write-Host "------------------------------------"
    Write-Host " "
    Write-Host "USB Devices:"
    Get-PnpDevice -PresentOnly | Where-Object { $_.Class -match 'USB' -or $_.InstanceId -match '^USB' } | Select-Object FriendlyName, Manufacturer, Status | Format-Table -AutoSize

    Write-Host " "
    Write-Host "PCI Devices (Common Categories):"
    Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like 'PCI\*' -and ($_.Class -eq 'Display' -or $_.Class -eq 'Net' -or $_.Class -eq 'System') } | Select-Object Caption, Manufacturer, Status | Format-Table -AutoSize

    Write-Host " "
    Write-Host "Storage Devices:"
    Get-CimInstance -ClassName Win32_DiskDrive | Select-Object Model, Size, MediaType | Format-Table -AutoSize
}

Get-WinFetch
