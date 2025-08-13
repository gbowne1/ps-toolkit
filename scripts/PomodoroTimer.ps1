# Pomodoro Timer in PowerShell
# 25 min work / 5 min break
# Customize these as needed
# 25 Minutes with 5 minutes break is standard Pomodoro session

$focusTime = 25 * 60  # 25 minutes in seconds
$breakTime = 5 * 60   # 5 minutes in seconds
$cycles = 4           # Total Pomodoro cycles

function Play-Beep {
    [console]::Beep(1000, 800)
}

function Show-Timer {
    param($totalSeconds, $label)

    for ($i = $totalSeconds; $i -gt 0; $i--) {
        $remaining = [TimeSpan]::FromSeconds($i)
        Write-Host "`r$label - Time left: $($remaining.ToString("mm\:ss"))" -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "`r$label - Time's up!                    "
    Play-Beep
}

Write-Host "=== PowerShell Pomodoro Timer ==="
Write-Host "Focus: $($focusTime / 60) min | Break: $($breakTime / 60) min
