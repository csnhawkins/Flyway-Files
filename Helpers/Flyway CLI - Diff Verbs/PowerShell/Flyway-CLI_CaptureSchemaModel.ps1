### Flyway CLI - Desktop Automation - Capture changes from Development database to Schema Model

# Flyway Project Settings - Specify the paths to the Flyway Project and Configuration files

# These settings can either be configured directly in the script, or passed at runtime. For example, from a pipeline tool.
# Step 1a - If using a Pipeline tool, ensure all variables are passed to the PowerShell script that start with ${env:XXX}
# Step 1b - If configuring directly in the PowerShell script, ensure the Local Variables part of the below else statement is filled out

if ($null -ne ${env:FLYWAY_PROJECT_PATH}) {
  # Environment Variables - Use these if set as a variable - Target Database Connection Details
  Write-Output "Using Pipeline Environment Variables for Flyway Project Settings"
  $flywayProjectPath = "${env:FLYWAY_PROJECT_PATH}" # Ensure flyway.toml is explicitly referenced in filepath
  $flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
  $flywayProjectSchemaModel = Join-Path $flywayProjectPath "schema-model"
  $flywayProjectMigrations = Join-Path $flywayProjectPath "migrations"
  $flywayVersionDescription = "${env:FLYWAY_VERSION_DESCRIPTION}" # This will be the description for the Auto-Generated migration script
  $flywayLicenseKey = "${env:FLYWAY_LICENSE_KEY}"
  # Optional - Environment Details
  $flywaySourceEnvironment = "${env:FLYWAY_SOURCE_ENVIRONMENT}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywaySourceUsername = "${env:FLYWAY_SOURCE_USERNAME}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywaySourcePassword = "${env:FLYWAY_SOURCE_PASSWORD}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $flywayTargetEnvironment = "${env:FLYWAY_TARGET_ENVIRONMENT}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywayTargetUsername = "${env:FLYWAY_TARGET_USERNAME}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywayTargetPassword = "${env:FLYWAY_TARGET_PASSWORD}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $pauseForInput = "true" # Set to true for interactive testing
  } else {
  Write-Output "Using Local Variables for Flyway Project Settings"
  # Local Variables - If Env Variables Not Set
  $flywayProjectPath = "C:\WorkingFolders\FWD\NewWorldDB" # Ensure flyway.toml is explicitly referenced in filepath
  $flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
  $flywayProjectSchemaModel = Join-Path $flywayProjectPath "schema-model"
  $flywayProjectMigrations = Join-Path $flywayProjectPath "migrations"
  $flywayVersionDescription = "FlywayCLIAutomatedScript" # This will be the description for the Auto-Generated migration script
  $flywayLicenseKey = ""
  # Optional - Environment Details
  $flywaySourceEnvironment = "development" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywaySourceUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywaySourcePassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $flywayTargetEnvironment = "schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywayTargetUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywayTargetPassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $pauseForInput = "true" # Set to true for interactive testing
}

$tempArtifactFolder = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\Artifacts\$([guid]::NewGuid().ToString())" 
$diffArtifactFileName = "Flyway.$flywaySourceEnvironment.differences-$(get-date -f yyyyMMdd).zip"
if (-not (Test-Path $tempArtifactFolder)) {
  New-Item -ItemType Directory -Force -Path $tempArtifactFolder | Out-Null
}
$diffArtifactFilePath = Join-Path $tempArtifactFolder $diffArtifactFileName

# Apply the dev database to schema-model

#cd $flywayProjectPath

# Flyway CLI - Shared Parameters List #
$commonParams =
@("-licenseKey=$flywayLicenseKey",
"-configFiles=$flywayProjectSettings",
"-schemaModelLocation=$flywayProjectSchemaModel"
)

# Flyway CLI - Verb Parameters List #

# Step 1 - The Diff parameters define which source database or folder is compared against another. By default this is a development database against the Schema Model folder
$diffParams = @("diff", "-diff.source=$flywaySourceEnvironment" ,"-environments.$flywaySourceEnvironment.user=$flywaySourceUsername" ,"-environments.$flywaySourceEnvironment.password=$flywaySourcePassword" ,"-diff.target=$flywayTargetEnvironment" ,"-environments.$flywayTargetEnvironment.user=$flywayTargetUsername" ,"-environments.$flywayTargetEnvironment.password=$flywayTargetPassword" ,"-diff.artifactFilename=$diffArtifactFilePath" ,"-outputType=") + $commonParams

# Step 2 - Differences are then applied to the target (This can be writing new definitions to the Schema Model or applying changes to a database)
$diffApplyParams = @("diffApply" ,"-diffApply.target=$flywayTargetEnvironment" ,"-diffApply.artifactFilename=$diffArtifactFilePath" ,"-outputType=") + $commonParams

# Capture differences between Development environment and Schema Model
Write-Host "Flyway CLI - Detecting differences in $flywaySourceEnvironment Environment"

flyway @diffParams | Tee-Object -Variable diffList

# Check if the previous command was successful
if ($? -eq $false) {
  Write-Error "Flyway CLI - Diff Command Failed. Exiting Session"
  exit 2  # Custom exit code to indicate a failure in the difference check command
}

# Check for "No differences found" in the result
if ($diffList -match "No differences found") {
  Write-Output "Flyway CLI - No Differences Found. Script Completed."
  # Clean-up: Remove temp artifact files
  try {
      Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
      Write-Output "Temporary artifact files cleaned up."
  } catch {
      Write-Error "Failed to remove temporary artifact files: $_"
  }
  # Conditionally pause console until user input provided
  if ($pauseForInput) {
      Read-Host "Press any key to exit"
      exit 0 # Success Exit Code
  }  
} else {
  Write-Output "Flyway CLI - Differences Found: Continuing to apply differences"
}

Write-Output "Flyway CLI - Applying Differences to $flywayTargetEnvironment"
# Apply differences from artifact to Schema Model
flyway $diffApplyParams

# Clean-up: Remove temp artifact files
try {
  Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
  # Conditionally pause console until user input provided
  if ($pauseForInput) {
    Read-Host "Press any key to exit"
    exit 0 # Success Exit Code
} 
} catch {
  Write-Error "Failed to remove temporary artifact files: $_"
}