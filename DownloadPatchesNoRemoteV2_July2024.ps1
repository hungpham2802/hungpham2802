# Define the list of remote servers to download patches from
#$servers = @("server1", "server2", "server3")

#March 2024
# Define an array of SharePoint patches categorized by version
$patches = @{        
    "SharePoint Server Subscription Edition" = @(
        "https://download.microsoft.com/download/c/2/0/c20b87cc-da05-4793-bd7b-c424a6a6df33/uber-subscription-kb5002606-fullfile-x64-glb.exe"
    )
	"SharePoint 2019" = @(
        "https://download.microsoft.com/download/b/d/c/bdcaf12b-3153-4125-946c-d4a8f0f99175/sts2019-kb5002615-fullfile-x64-glb.exe"
    )
	"SharePoint 2016" = @(        
		"https://download.microsoft.com/download/d/d/6/dd63db3f-c434-42dc-89c8-7f06d42fdf9f/sts2016-kb5002618-fullfile-x64-glb.exe"
    )
}
$spVersionNumber = ""
# Detect the installed version of SharePoint

if ( (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

# Define the URL of the PowerShell script on GitHub
$scriptUrl = "https://raw.githubusercontent.com/hungpham2802/hungpham2802/main/InstallPatches.ps1"

$farm = Get-SPFarm
if($farm.BuildVersion.Major -eq 16)
{
if ($farm.BuildVersion.Build -gt 14000) {
    Write-Host "SharePoint SE is installed"
	$spVersion = "SharePoint Server Subscription Edition"
	$spVersionNumber = "16.0.17328.20424-July2024"
	
	$scriptUrl = "https://raw.githubusercontent.com/hungpham2802/hungpham2802/main/Install-SPSE_Fix.ps1"
	
} elseif ($farm.BuildVersion.Build -gt 10000) {
    Write-Host "SharePoint 2019 is installed"
	$spVersion = "SharePoint 2019"
	$spVersionNumber = "16.0.10412.20001-July2024"
} elseif ($farm.BuildVersion.Build -gt 4107) {
    Write-Host "SharePoint 2016 is installed"
	$spVersion = "SharePoint 2016"
	$spVersionNumber = "16.0.5456.1000-July2024"
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
	


# Define the local file path for the downloaded script
$localScriptPath = Join-Path -Path $localFolder -ChildPath "InstallPatches.ps1"

try {
    # Download the script from the GitHub URL
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localScriptPath
    
} catch {
    Write-Host "An error occurred: $_.Exception.Message"
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