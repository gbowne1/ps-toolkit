$source = "C:\Users\YourName\Downloads"
Get-ChildItem -Path $source | ForEach-Object {
    $ext = $_.Extension.TrimStart(".")
    $dest = Join-Path $source $ext
    if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest }
    Move-Item $_.FullName -Destination $dest
}


// Journal Starter
$date = Get-Date -Format "yyyy-MM-dd"
$path = "C:\Users\YourName\Documents\Journal\$date.txt"
if (-not (Test-Path $path)) { New-Item $path }
notepad $path


