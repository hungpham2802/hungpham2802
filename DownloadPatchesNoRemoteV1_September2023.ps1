# Define the list of remote servers to download patches from
#$servers = @("server1", "server2", "server3")

# Define an array of SharePoint patches categorized by version
$patches = @{        
    "SharePoint Server Subscription Edition" = @(
        "https://download.microsoft.com/download/f/5/5/f5559e3f-8b24-419f-b238-b09cf986e927/uber-subscription-kb5002474-fullfile-x64-glb.exe"
    )
	"SharePoint 2019" = @(
        "https://download.microsoft.com/download/a/1/c/a1cd6afb-359f-49f6-9d1a-592663eeb987/sts2019-kb5002472-fullfile-x64-glb.exe",
		"https://download.microsoft.com/download/a/3/1/a318f78f-0056-4e48-99e4-b44a8c5222e0/wssloc2019-kb5002471-fullfile-x64-glb.exe"
    )
	"SharePoint 2016" = @(        
		"https://download.microsoft.com/download/a/7/d/a7d95f46-a0b6-4c5a-ade2-b61e57949172/sts2016-kb5002494-fullfile-x64-glb.exe",
		"https://download.microsoft.com/download/f/8/8/f8896fb2-c52e-4653-8c61-f1f4f8f11fbe/wssloc2016-kb5002501-fullfile-x64-glb.exe"
    )
}
$spVersionNumber = ""
# Detect the installed version of SharePoint

Add-PSSnapin "Microsoft.SharePoint.PowerShell"

$farm = Get-SPFarm
if($farm.BuildVersion.Major -eq 16)
{
if ($farm.BuildVersion.Build -gt 14000) {
    Write-Host "SharePoint SE is installed"
	$spVersion = "SharePoint Server Subscription Edition"
	$spVersionNumber = "16.0.16731.20180-September2023"
} elseif ($farm.BuildVersion.Build -gt 10000) {
    Write-Host "SharePoint 2019 is installed"
	$spVersion = "SharePoint 2019"
	$spVersionNumber = "16.0.10402.20016-September2023"
} elseif ($farm.BuildVersion.Build -gt 4107) {
    Write-Host "SharePoint 2016 is installed"
	$spVersion = "SharePoint 2016"
	$spVersionNumber = "16.0.5413.1001-September2023"
}
else {
    Write-Host "Unknown SharePoint version"
}
}

$servers = @()

foreach($server in $farm.Servers)
{
if($server.Role -ne "Invalid")
    {
    $servers += $server.Address
}
}

Write-Output $servers

# Specify the local folder to save the downloaded files to
$localFolder = "G:\Software\SharePoint_CUs\$spVersionNumber"
$DestinationFolder = "G$\Software\SharePoint_CUs"


# Check if the local folder exists; create it if it doesn't
	if (-not (Test-Path $localFolder)) {
		New-Item -ItemType Directory -Path $localFolder | Out-Null
	}

    # Loop through the patches for the installed SharePoint version and download the files to the local folder
    foreach ($url in $patches[$spVersion]) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $localPath = Join-Path $localFolder $fileName
        
		Write-Host "Downloading file: $fileName"
    Start-BitsTransfer -Source $url -Destination $localPath
    Write-Host "Downloaded file: $fileName"
    }
	
#copy to another server

foreach ($Server in $servers) {
    # Ignore current server
    if ($Server.ToLower() -contains $env:COMPUTERNAME.ToLower()) {
        continue
    }
    
    $DestinationPath = "\\$Server\$DestinationFolder"
    
    # Check if destination folder exists
    if (!(Test-Path -Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath | Out-Null
    }
	Write-Host "Copying folder $spVersionNumber to server $Server"

    # Copy folder to destination folder
    Copy-Item -Path $localFolder -Destination $DestinationPath -Recurse
}