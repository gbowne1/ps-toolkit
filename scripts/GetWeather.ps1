# Set output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param (
    [string]$Location,
    [int]$MaxRetries,
    [string]$LogPath,
    [ValidateSet("wttr", "open-meteo")]
    [string]$WeatherAPI
)

# Default assignments (PowerShell 5.1-friendly)
if (-not $Location)    { $Location = "" }
if (-not $MaxRetries)  { $MaxRetries = 3 }
if (-not $LogPath)     { $LogPath = "$env:USERPROFILE\weather_log.txt" }
if (-not $WeatherAPI)  { $WeatherAPI = "wttr" }

# Prompt if location is empty
if ([string]::IsNullOrWhiteSpace($Location)) {
    $Location = Read-Host "Enter your city or location"
}
if ([string]::IsNullOrWhiteSpace($Location)) {
    Write-Error "Location is required. Exiting."
    exit 1
}

# Helper: URL-encode (works in 5.1)
function UrlEncode {
    param([string]$str)
    return [uri]::EscapeDataString($str)
}

function Get-WttrWeather {
    param ($Location)
    $encodedLocation = UrlEncode $Location
    $url = "https://wttr.in/$encodedLocation?format=%C+%t+%w&lang=en"
    return Invoke-RestMethod -Uri $url -UseBasicParsing
}

function Get-OpenMeteoWeather {
    param ($Location)
    $geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=$(UrlEncode $Location)"
    $geoData = Invoke-RestMethod -Uri $geoUrl -UseBasicParsing

    if (-not $geoData.results) {
        throw "Location '$Location' not found via Open-Meteo geocoding."
    }

    $lat = $geoData.results[0].latitude
    $lon = $geoData.results[0].longitude

    $weatherUrl = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true"
    $weatherData = Invoke-RestMethod -Uri $weatherUrl -UseBasicParsing
    $current = $weatherData.current_weather

    return "Temp: $($current.temperature)°C, Wind: $($current.windspeed) km/h"
}

# Main logic
$response = $null
$attempt = 0
$success = $false

while (-not $success -and $attempt -lt $MaxRetries) {
    try {
        switch ($WeatherAPI) {
            "wttr"       { $response = Get-WttrWeather -Location $Location }
            "open-meteo" { $response = Get-OpenMeteoWeather -Location $Location }
        }

        $message = "`n[$WeatherAPI] Weather for '$Location':`n$response`n"
        Write-Host $message -ForegroundColor Cyan

        if ($LogPath) {
            Add-Content -Path $LogPath -Value "$(Get-Date): $message"
        }

        $success = $true
    }
    catch {
        $attempt++
        Write-Warning "Attempt $attempt failed: $_"
        Start-Sleep -Seconds 2
    }
}

if (-not $success) {
    Write-Error "All $MaxRetries attempts failed. Unable to fetch weather data for '$Location'."
}
if ($LogPath) {
    Write-Host "Weather data logged to $LogPath"
} else {
    Write-Host "No log path specified."
}
if ($success) {
    Write-Host "Weather data fetched successfully."
} else {
    Write-Host "Failed to fetch weather data after $MaxRetries attempts."
}
