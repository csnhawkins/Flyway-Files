$ErrorActionPreference = "Stop"

# Flyway Version to Use - Check here for latest version information
$flywayVersion = '10.19.0'

# Flyway URL to download CLI
$Url = "https://download.red-gate.com/maven/release/org/flywaydb/enterprise/flyway-commandline/$flywayVersion/flyway-commandline-$flywayVersion-windows-x64.zip"

# Path for downloaded zip file
$DownloadZipFile = "C:\FlywayCLI\" + $(Split-Path -Path $Url -Leaf)

# Path where Flyway will be extracted (no version subfolder)
$ExtractPath = "C:\FlywayCLI\"

# Ensure that the Flyway extraction directory exists
if (-Not (Test-Path $ExtractPath)) {
    # Create the directory if it doesn't exist
    New-Item $ExtractPath -ItemType Directory
    Write-Host "Folder Created successfully"
} else {
    Write-Host "Folder Exists"
}

# Set the progress preference to avoid displaying the progress bar
$ProgressPreference = 'SilentlyContinue'

# Check if Flyway is already installed
if (Get-Command flyway -ErrorAction SilentlyContinue) {
    Write-Host "Flyway Installed"

    # Get the current Flyway version
    try {
        $versionOutput = & flyway -v 2>&1
    } catch {
        Write-Output "Failed to execute Flyway. Error: $_"
        exit 1
    }

    # Extract version information
    $a = & "flyway" --version 2>&1 | Select-String 'Edition'
    $b = $a -split ' '
    
    if ($b[3] -eq $flywayVersion) {
        Write-Output "$($b) is already installed."
        Exit
    } else {
        Write-Host "A different version of Flyway is installed. Updating to version $flywayVersion."

        # Clean up the old Flyway files in the extraction directory
        Remove-Item -Recurse -Force "$ExtractPath*"

        # Download the new Flyway CLI
        Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile

        # Extract the CLI to the desired location
        Expand-Archive -Path $DownloadZipFile -DestinationPath $ExtractPath -Force

        # Verify the new version
        Write-Host "Flyway $flywayVersion is now installed in $ExtractPath."
        "flyway -v" | cmd.exe
        Exit
    }
} else {
    Write-Host "Flyway is not installed. Proceeding with installation."

    # Download the Flyway CLI
    Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile

    # Extract the CLI to the desired location
    Expand-Archive -Path $DownloadZipFile -DestinationPath $ExtractPath -Force

    # Add Flyway to the PATH if not already added (one-time setup)
    if (-Not $Env:Path.Contains("C:\FlywayCLI")) {
        [System.Environment]::SetEnvironmentVariable('Path', "C:\FlywayCLI;$([System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User))", [System.EnvironmentVariableTarget]::User)
        Write-Host "Flyway added to PATH."
    }

    # Verify the installation
    Write-Host "Flyway $flywayVersion is now installed in $ExtractPath."
    "flyway -v" | cmd.exe
    Exit
}
