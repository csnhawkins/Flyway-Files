# Variables #
$DATABASE_NAME = "Westwind"
$SOURCE_ENVIRONMENT = "schemaModel"
$SOURCE_DATABASE_JDBC = "jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=Westwind_Dev;encrypt=true;integratedSecurity=true;trustServerCertificate=true"
$SOURCE_DATABASE_USER = ""
$SOURCE_DATABASE_PASSWORD = ""
$TARGET_ENVIRONMENT = "state"
$TARGET_DATABASE_JDBC = "jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=Westwind_State;encrypt=true;integratedSecurity=true;trustServerCertificate=true"
$TARGET_DATABASE_USER = ""
$TARGET_DATABASE_PASSWORD = ""

$FLYWAY_SCRIPT_DESCRIPTION = "FlywayCLIAutomatedScript"
$FLYWAY_LICENSE_KEY = "" # Deprecated Auth Method. Use PATs instead
$FLYWAY_EMAIL = ""
$FLYWAY_TOKEN = ""
$WORKING_DIRECTORY = "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"
$ARTIFACT_DIRECTORY = "$WORKING_DIRECTORY\Artifacts"

$pauseForInput = "false" # Set to true for interactive testing

# Step 1 - Create Diff Artifact

flyway diff `
"-diff.source=$SOURCE_ENVIRONMENT" `
"-environments.$SOURCE_ENVIRONMENT.url=$SOURCE_DATABASE_JDBC" `
"-environments.$SOURCE_ENVIRONMENT.user=$SOURCE_DATABASE_USER" `
"-environments.$SOURCE_ENVIRONMENT.password=$SOURCE_DATABASE_PASSWORD" `
"-diff.target=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-diff.artifactFilename=$ARTIFACT_DIRECTORY\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
-outputType="" `
-configFiles="$WORKING_DIRECTORY\flyway.toml" `
-schemaModelLocation="$WORKING_DIRECTORY\schema-model\" `
-email="$FLYWAY_EMAIL" `
-token="$FLYWAY_TOKEN"
| Tee-Object -Variable flywayDiffs  # Capture Flyway Diff output to variable flywayDiffs and show output in console

# Check if the previous command was successful
if ($? -eq $false) {
  Write-Error "Flyway CLI - Diff Command Failed. Exiting Session"
  exit 2  # Custom exit code to indicate a failure in the difference check command
}

# Check for "No differences found" in the result
if ($flywayDiffs -match "No differences found") {
  Write-Output "Flyway CLI - No Differences Found. Script Completed."
  # Clean-up: Remove temp artifact files
  try {
      Remove-Item $ARTIFACT_DIRECTORY -Recurse -Force -Confirm:$false
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


# Step 2 - Generate Deployment Script
Write-Output "Flyway CLI - Generating Deployment Script for $TARGET_ENVIRONMENT"
flyway generate `
"-generate.description=$FLYWAY_SCRIPT_DESCRIPTION" `
"-generate.location=$WORKING_DIRECTORY/Artifacts/" `
"-generate.types=versioned,undo" `
"-generate.artifactFilename=$ARTIFACT_DIRECTORY\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
"-outputType=" `
"-generate.force=true" `
"-licenseKey=$FLYWAY_LICENSE_KEY" `
"-configFiles=$WORKING_DIRECTORY\flyway.toml"

# Step 3 - Deploy to target
Write-Output "Flyway CLI - Deploying Changes to: $TARGET_ENVIRONMENT"
flyway deploy `
"-environment=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-deploy.scriptFilename=$ARTIFACT_DIRECTORY\V001__FlywayCLIAutomatedScript.sql"
