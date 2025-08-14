# === PowerShell Pomodoro Timer ===
# Enhanced version with user input, summary, sound toggle, error handling

# =============== USER CONFIGURATION ===============
# Ask user for durations and cycle count
$focusMinutes = Read-Host "Enter focus time in minutes (default 25)"
if (-not $focusMinutes) { $focusMinutes = 25 }

$breakMinutes = Read-Host "Enter break time in minutes (default 5)"
if (-not $breakMinutes) { $breakMinutes = 5 }

$cycles = Read-Host "Enter number of Pomodoro cycles (default 4)"
if (-not $cycles) { $cycles = 4 }

# Convert minutes to seconds
$focusTime = $focusMinutes * 60
$breakTime = $breakMinutes * 60

# Sound toggle
$enableSound = Read-Host "Enable sound notifications? (Y/N, default Y)"
if (-not $enableSound -or $enableSound -match '^[Yy]$') { $enableSound = $true } else { $enableSound = $false }

# =============== FUNCTIONS ===============
function Play-Beep {
    if ($enableSound) {
        [console]::Beep(1000, 800)
    }
}

function Play-FocusBeep {
    if ($enableSound) {
        [console]::Beep(800, 600)
        [console]::Beep(1000, 600)
    }
}

function Play-BreakBeep {
    if ($enableSound) {
        [console]::Beep(1200, 600)
        [console]::Beep(900, 600)
    }
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

function Show-Notification {
    param ($title, $message)

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Show-Toast {
    param ($title, $message)

    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($template.CreateTextNode($title)) | Out-Null
        $textNodes.Item(1).AppendChild($template.CreateTextNode($message)) | Out-Null

        $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PomodoroTimer")
        $notifier.Show($toast)
    }
    catch {
        # Fallback to basic message box
        Show-Notification -title $title -message $message
    }
}

# =============== MAIN TIMER LOOP ===============
Write-Host "`n=== PowerShell Pomodoro Timer ==="
Write-Host "Focus: $focusMinutes min | Break: $breakMinutes min | Cycles: $cycles"
Write-Host "Press Ctrl+C to exit early."

$sessionStart = Get-Date

# Handle Ctrl+C gracefully
trap {
    Write-Host "`nSession interrupted. Exiting Pomodoro Timer."
    exit
}

for ($i = 1; $i -le $cycles; $i++) {
    Write-Host "`nCycle $i of $cycles"

    Show-Timer -totalSeconds $focusTime -label "Focus"
    Play-FocusBeep
    Show-Toast -title "Break Time!" -message "Time to take a short break."

    Show-Timer -totalSeconds $breakTime -label "Break"
    Play-BreakBeep
    Show-Toast -title "Back to Work!" -message "Time to focus again."
}

# =============== SUMMARY ===============
$sessionEnd = Get-Date
$totalTime = New-TimeSpan -Start $sessionStart -End $sessionEnd
$totalMinutes = [math]::Round($totalTime.TotalMinutes)

Write-Host "`n=== Pomodoro Session Complete! ==="
Write-Host "Completed $cycles Pomodoro cycle(s)"
Write-Host "Total time: $totalMinutes minute(s)"

# Optional: Log session
$logPath = "$env:USERPROFILE\pomodoro_log.txt"
Add-Content -Path $logPath -Value "$(Get-Date): Completed $cycles cycle(s) in $totalMinutes minutes"

Show-Toast -title "Pomodoro Complete" -message "You completed $cycles cycles in $totalMinutes minutes!"
