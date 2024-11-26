### Flyway CLI - Desktop Automation - Capture Changes from Schema Model and deploy to Target

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
  $flywayVersionDescription = "${env:FLYWAY_VERSION_DESCRIPTION}" # This will be the description for the Auto-Generated migration script
  $flywayEmail = "${env:FLYWAY_EMAIL}"
  $flywayToken = "${env:FLYWAY_TOKEN}"
  # Optional - Environment Details
  $flywaySourceEnvironment = "${env:FLYWAY_SOURCE_ENVIRONMENT}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywaySourceUsername = "${env:FLYWAY_SOURCE_USERNAME}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywaySourcePassword = "${env:FLYWAY_SOURCE_PASSWORD}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $flywayTargetEnvironment = "${env:FLYWAY_TARGET_ENVIRONMENT}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywayTargetUsername = "${env:FLYWAY_TARGET_USERNAME}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywayTargetPassword = "${env:FLYWAY_TARGET_PASSWORD}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  } else {
  Write-Output "Using Local Variables for Flyway Project Settings"
  # Local Variables - If Env Variables Not Set
  $flywayProjectPath = "C:\Redgate\GIT\Repos\AzureDevOps\Westwind" # Ensure flyway.toml is explicitly referenced in filepath
  $flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
  $flywayProjectSchemaModel = Join-Path $flywayProjectPath "schema-model"
  $flywayVersionDescription = "FlywayCLIAutomatedScript" # This will be the description for the Auto-Generated migration script
  $flywayEmail = "" # Email address associated with the Redgate Portal Personal Access Token
  $flywayToken = "" # Personal Access Token created from the Redgate Portal
  # Optional - Environment Details
  $flywaySourceEnvironment = "schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywaySourceUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywaySourcePassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
  $flywayTargetEnvironment = "build" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
  $flywayTargetUsername = "Redgate" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
  $flywayTargetPassword = "Redg@te1" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
}

$tempArtifactFolder = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\Artifacts\$([guid]::NewGuid().ToString())" 
$diffArtifactFileName = "Flyway.$flywaySourceEnvironment.differences-$(get-date -f yyyyMMdd).sql"
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

# Step 1 - The Diff parameters define which source database or folder is compared against another. By default this is a Schema Model folder against a target database
$prepareParams = @("prepare", "-prepare.source=$flywaySourceEnvironment" ,"-environments.$flywaySourceEnvironment.user=$flywaySourceUsername" ,"-environments.$flywaySourceEnvironment.password=$flywaySourcePassword" ,"-prepare.target=$flywayTargetEnvironment" ,"-environments.$flywayTargetEnvironment.user=$flywayTargetUsername" ,"-environments.$flywayTargetEnvironment.password=$flywayTargetPassword" ,"-prepare.scriptFilename=$diffArtifactFilePath" ,"-outputType=") + $commonParams

# Step 2 - Differences are then applied to the target (This can be writing new definitions to the Schema Model or applying changes to a database)
$deployParams = @("deploy" ,"-environment=$flywayTargetEnvironment" ,"-environments.$flywayTargetEnvironment.user=$flywayTargetUsername" ,"-environments.$flywayTargetEnvironment.password=$flywayTargetPassword" ,"-deploy.scriptFilename=$diffArtifactFilePath") + $commonParams

# Capture differences between Development environment and Schema Model
Write-Host "Flyway CLI - Detecting differences between Source - $flywaySourceEnvironment & Target - $flywayTargetEnvironment"

flyway @prepareParams | Tee-Object -Variable flywayDiffs  # Capture Flyway Diff output to variable flywayDiffs and show output in console

if ($flywayDiffs -like "*no differences detected*") {
  Write-Host "No changes to generate. Exiting script gracefully."
  exit 0  # Graceful exit
} else {
  Write-Host "Changes detected. Proceeding with further steps."
}

Write-Output "Flyway CLI - Deploying Differences to $flywayTargetEnvironment"
# Apply differences from artifact to Schema Model
flyway $deployParams

# Clean-up: Remove temp artifact files
try {
  Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
} catch {
  Write-Error "Failed to remove temporary artifact files: $_"
}