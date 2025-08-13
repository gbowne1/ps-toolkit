# Get Firefox profiles directory
$profilesIni = "$env:APPDATA\Mozilla\Firefox\profiles.ini"

if (-Not (Test-Path $profilesIni)) {
    Write-Host "Firefox profiles.ini not found. Is Firefox installed?" -ForegroundColor Red
    exit
}

# Parse profiles.ini to find default profile path
$iniContent = Get-Content $profilesIni

# Find line with Default=1 to get default profile
$defaultProfileLine = $iniContent | Select-String -Pattern 'Default=1'

if (-not $defaultProfileLine) {
    Write-Host "Default Firefox profile not found." -ForegroundColor Red
    exit
}

# Extract profile section name before Default=1 line
$lineIndex = $iniContent.IndexOf($defaultProfileLine.Line)
$profileSectionLine = $iniContent[$lineIndex - 1]

# Extract profile name from section line: [ProfileX]
if ($profileSectionLine -match '\[(.+)\]') {
    $profileSection = $matches[1]
} else {
    Write-Host "Cannot parse profile section." -ForegroundColor Red
    exit
}

# Find Path= line inside this profile section
$startIndex = $iniContent.IndexOf($profileSectionLine) + 1
$endIndex = $iniContent.IndexOf("") # blank line or end of file
if ($endIndex -le $startIndex) { $endIndex = $iniContent.Length }

$profilePathLine = $null
for ($i = $startIndex; $i -lt $endIndex; $i++) {
    if ($iniContent[$i] -like 'Path=*') {
        $profilePathLine = $iniContent[$i]
        break
    }
}

if (-not $profilePathLine) {
    Write-Host "Cannot find profile path." -ForegroundColor Red
    exit
}

# Get relative profile path
$profilePath = $profilePathLine -replace 'Path=', ''

# Compose full path to profile folder
$fullProfilePath = Join-Path "$env:APPDATA\Mozilla\Firefox\Profiles" $profilePath

# Path to cache2 folder
$cachePath = Join-Path $fullProfilePath "cache2"

if (-not (Test-Path $cachePath)) {
    Write-Host "Firefox cache folder not found at $cachePath" -ForegroundColor Yellow
    exit
}

# Delete cache contents
try {
    Remove-Item -Path $cachePath\* -Recurse -Force -ErrorAction Stop
    Write-Host "Firefox cache cleared successfully from $cachePath" -ForegroundColor Green
} catch {
    Write-Host "Failed to clear Firefox cache: $_" -ForegroundColor Red
}
