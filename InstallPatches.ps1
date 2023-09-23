# Set the folder path
$folderPath = Get-Location

# Define the log folder path
$logFolderPath = Join-Path -Path $folderPath -ChildPath "Logs"

# Check if the log folder exists, and create it if it doesn't
if (-not (Test-Path -Path $logFolderPath -PathType Container)) {
    New-Item -Path $logFolderPath -ItemType Directory
}

# Get all executable files in the current folder
$exeFiles = Get-ChildItem -Path $folderPath -Filter *.exe

# Parameters to pass to the executable files
$parameters = "/norestart /quiet /log:$logFolderPath\log.txt"

# Loop through the executable files and run them with the specified parameters
foreach ($exeFile in $exeFiles) {
    $exePath = $exeFile.FullName
    Start-Process -FilePath $exePath -ArgumentList $parameters -Wait
}

# Ask for confirmation before restarting the computer
$confirmRestart = Read-Host "Do you want to restart the computer? (Type 'yes' to restart or 'no' to cancel)"
if ($confirmRestart -eq "yes") {
    Restart-Computer -Force
} else {
    Write-Host "Computer restart canceled."
}
