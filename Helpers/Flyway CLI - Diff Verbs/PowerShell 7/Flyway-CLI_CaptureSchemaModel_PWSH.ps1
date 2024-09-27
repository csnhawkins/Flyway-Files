### Flyway CLI - Desktop Automation - Capture changes from Development database to Schema Model

# Flyway Project Settings - Specify the paths to the Flyway Project and Configuration files

# These settings can either be configured directly in the script, or passed at runtime. For example, from a pipeline tool.
# Step 1a - If using a Pipeline tool, ensure all variables are passed to the PowerShell script that start with ${env:XXX}
# Step 1b - If configuring directly in the PowerShell script, ensure the Local Variables part of the below else statement is filled out
# Details - Using PowerShell 7 Ternary Logic, variables can be set using If/Else logic. This means if an environment variable is passed through to the script, this can be used, otherwise we can fallback to a local script value. Also valuable for local script testing. Syntax is: <condition> ? <condition-is-true> : <condition-is-false>;

$flywayProjectPath = ($null -ne ${env:FLYWAY_PROJECT_PATH}) ? ${env:FLYWAY_PROJECT_PATH} : "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"
Write-Host $(($null -ne ${env:FLYWAY_PROJECT_PATH}) ? "Environment Variable Used for 'Flyway Project Path'" : "Local Script Value Used for 'Flyway Project Path'")
$flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
$flywayProjectSchemaModel = Join-Path $flywayProjectPath "schema-model"
$flywayProjectMigrations = Join-Path $flywayProjectPath "migrations"
$flywayLicenseKey = ($null -ne ${env:FLYWAY_LICENSE_KEY}) ? ${env:FLYWAY_LICENSE_KEY} : ""
Write-Host $(($null -ne ${env:FLYWAY_LICENSE_KEY}) ? "Environment Variable Used for 'Flyway License Key'" : "Local Script Value Used for 'Flyway License Key'")


# Optional - Environment Details

# Source Environment: Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
$flywaySourceEnvironment = ($null -ne ${env:FLYWAY_SOURCE_ENVIRONMENT}) ? "${env:FLYWAY_SOURCE_ENVIRONMENT}" : "development"
Write-Host $(($null -ne ${env:FLYWAY_SOURCE_ENVIRONMENT}) ? "Environment Variable Used for 'Flyway Source Environment'" : "Local Script Value Used for 'Flyway Source Environment'")
# Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
$flywaySourceUsername = ($null -ne ${env:FLYWAY_SOURCE_USERNAME}) ? "${env:FLYWAY_SOURCE_USERNAME}" : ""
# Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
$flywaySourcePassword = ($null -ne ${env:FLYWAY_SOURCE_PASSWORD}) ? "${env:FLYWAY_SOURCE_PASSWORD}" : ""
# Target Environment: Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
$flywayTargetEnvironment = ($null -ne ${env:FLYWAY_TARGET_ENVIRONMENT}) ? "${env:FLYWAY_TARGET_ENVIRONMENT}" : "schemaModel" 
Write-Host $(($null -ne ${env:FLYWAY_TARGET_ENVIRONMENT}) ? "Environment Variable Used for 'Flyway Source Environment'" : "Local Script Value Used for 'Flyway Source Environment'")
# Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
$flywayTargetUsername = ($null -ne ${env:FLYWAY_TARGET_USERNAME}) ? "${env:FLYWAY_TARGET_USERNAME}" : "" 
# Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
$flywayTargetPassword = ($null -ne ${env:FLYWAY_TARGET_PASSWORD}) ? "${env:FLYWAY_TARGET_PASSWORD}" : "" 



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
$diffParams = @("diff", "-diff.source=$flywaySourceEnvironment" ,"-environments.$flywaySourceEnvironment.user=$flywaySourceUsername" ,"-environments.$flywaySourceEnvironment.password=$flywaySourcePassword" ,"-diff.target=$flywayTargetEnvironment" ,"-environments.$flywayTargetEnvironment.user=$flywayTargetUsername" ,"-environments.$flywayTargetEnvironment.password=$flywayTargetPassword" ,"-diff.artifactFilename=$diffArtifactFilePath" ,"-outputType=json") + $commonParams

# Step 2 - If differences are found above, they are shown in text form in the console output
$diffTextParams = @("diffText", "-diffText.artifactFilename=$diffArtifactFilePath") + $commonParams

# Step 3 - Differences are then applied to the target (This can be writing new definitions to the Schema Model or applying changes to a database)
$diffApplyParams = @("diffApply" ,"-diffApply.target=$flywayTargetEnvironment" ,"-diffApply.artifactFilename=$diffArtifactFilePath" ,"-outputType=") + $commonParams

# Capture differences between Development environment and Schema Model
Write-Host "Flyway CLI - Detecting differences in $flywaySourceEnvironment Environment"

$diffList = flyway @diffParams | ConvertFrom-Json

$diffListIDs = $diffList.differences.id

if ($null -ne $diffListIDs) {

  Write-Output "Flyway CLI - Differences Found: See below for details"
  flyway @diffTextParams

} else {

  Write-Output "Flyway CLI - No Differences Found. Script Completed"
  # Clean-up: Remove temp artifact files
  try {
    Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
    Write-Output "Temporary artifact files cleaned up."
    } catch {
    Write-Error "Failed to remove temporary artifact files: $_"
    }
  exit 1
}

Write-Output "Flyway CLI - Applying Differences to $flywayTargetEnvironment"
# Apply differences from artifact to Schema Model
flyway $diffApplyParams

# Clean-up: Remove temp artifact files
try {
  Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
} catch {
  Write-Error "Failed to remove temporary artifact files: $_"
}