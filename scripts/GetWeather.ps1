[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param (
    [string]$Location = "YourCity",
    [int]$MaxRetries = 3,
    [string]$LogPath = "$(Get-Location)\weather_log.txt"
    [ValidateSet("wttr", "open-meteo")]
    [string]$WeatherAPI = "wttr"
)

if ($Location -eq "YourCity") {
    $Location = Read-Host "Enter your city or location"
}

function Get-WttrWeather {
    param ($Location)
    $encodedLocation = [System.Web.HttpUtility]::UrlEncode($Location)
    $url = "https://wttr.in/$encodedLocation?format=%C+%t+%w&lang=en"
    return Invoke-RestMethod -Uri $url
}

function Get-OpenMeteoWeather {
    param ($Location)
    # Use geocoding to get lat/lon
    $geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=$Location"
    $geoData = Invoke-RestMethod -Uri $geoUrl
    if (-not $geoData.results) {
        throw "Location not found in Open-Meteo geocoding."
    }
    $lat = $geoData.results[0].latitude
    $lon = $geoData.results[0].longitude

    # Fetch current weather
    $weatherUrl = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true"
    $weatherData = Invoke-RestMethod -Uri $weatherUrl
    $current = $weatherData.current_weather
    return "Temp: $($current.temperature)°C, Wind: $($current.windspeed) km/h"
}

$attempt = 0
$success = $false
$response = $null

while (-not $success -and $attempt -lt $MaxRetries) {
    try {
        switch ($WeatherAPI) {
            "wttr"        { $response = Get-WttrWeather -Location $Location }
            "open-meteo"  { $response = Get-OpenMeteoWeather -Location $Location }
        }

        Write-Host "`nWeather for ${Location} using ${WeatherAPI}:`n${response}" -ForegroundColor Cyan
        Add-Content -Path $LogPath -Value "$(Get-Date): Weather for $Location via $WeatherAPI - $response"
        $success = $true
    }
    catch {
        $attempt++
        Write-Host "Attempt $attempt failed. Retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $success) {
    $message = "`nWeather for ${Location} using ${WeatherAPI}:`n${response}"
    Write-Host $message -ForegroundColor Cyan
}
