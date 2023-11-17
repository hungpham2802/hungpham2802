# Define the list of remote servers to download patches from
#$servers = @("server1", "server2", "server3")

# Define an array of SharePoint patches categorized by version
$patches = @{        
    "SharePoint Server Subscription Edition" = @(
        "https://download.microsoft.com/download/c/7/b/c7b21b38-a4ff-4060-99b1-edb2e1edc69a/uber-subscription-kb5002527-fullfile-x64-glb.exe"
    )
	"SharePoint 2019" = @(
        "https://download.microsoft.com/download/2/7/3/2738b926-0d9d-48df-927e-71434642d991/sts2019-kb5002526-fullfile-x64-glb.exe",
		"https://download.microsoft.com/download/f/4/5/f458bb31-e969-4515-ad4a-4e05ee543117/wssloc2019-kb5002505-fullfile-x64-glb.exe"
    )
	"SharePoint 2016" = @(        
		"https://download.microsoft.com/download/0/7/a/07a62916-d0a7-47cd-931d-107a1176570f/sts2016-kb5002517-fullfile-x64-glb.exe"
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
	$spVersionNumber = "16.0.16731.20350-November2023"
} elseif ($farm.BuildVersion.Build -gt 10000) {
    Write-Host "SharePoint 2019 is installed"
	$spVersion = "SharePoint 2019"
	$spVersionNumber = "16.0.10404.20003-November2023"
} elseif ($farm.BuildVersion.Build -gt 4107) {
    Write-Host "SharePoint 2016 is installed"
	$spVersion = "SharePoint 2016"
	$spVersionNumber = "16.0.5422.1000-November2023"
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
	
# Define the URL of the PowerShell script on GitHub
$scriptUrl = "https://raw.githubusercontent.com/hungpham2802/hungpham2802/main/InstallPatches.ps1"

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