# Variables #
$DATABASE_NAME = "Westwind"
$SOURCE_ENVIRONMENT = "development"
$SOURCE_DATABASE_JDBC = "jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=Westwind_Dev;encrypt=true;integratedSecurity=true;trustServerCertificate=true"
$SOURCE_DATABASE_USER = ""
$SOURCE_DATABASE_PASSWORD = ""
$TARGET_ENVIRONMENT = "state"
$TARGET_DATABASE_JDBC = "jdbc:sqlserver://localhost;instanceName=SQLEXPRESS;databaseName=Westwind_State;encrypt=true;integratedSecurity=true;trustServerCertificate=true"
$TARGET_DATABASE_USER = ""
$TARGET_DATABASE_PASSWORD = ""

# Flyway Authentication
#$FLYWAY_LICENSE_KEY = "" # Deprecated License Key Method
$FLYWAY_EMAIL = ""
$FLYWAY_TOKEN = ""

$WORKING_DIRECTORY = "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"
$FLYWAY_PROJECT_SETTINGS = Join-Path $WORKING_DIRECTORY "flyway.toml"
$ARTIFACT_DIRECTORY = "$WORKING_DIRECTORY\Artifacts"
$SCRIPT_FILENAME = "Flyway-$DATABASE_NAME-AutoDeploymentScript-$(get-date -f yyyyMMdd).sql"


# Step 1 - Prepare: Detect differences and create deployment script
flyway prepare `
"-prepare.source=$SOURCE_ENVIRONMENT" `
"-environments.$SOURCE_ENVIRONMENT.url=$SOURCE_DATABASE_JDBC" `
"-environments.$SOURCE_ENVIRONMENT.user=$SOURCE_DATABASE_USER" `
"-environments.$SOURCE_ENVIRONMENT.password=$SOURCE_DATABASE_PASSWORD" `
"-prepare.target=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-prepare.scriptFilename=$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME" `
"-prepare.force=true" `
-configFiles="$FLYWAY_PROJECT_SETTINGS" `
-email="$FLYWAY_EMAIL" `
-token="$FLYWAY_TOKEN" | Tee-Object -Variable flywayDiffs  # Capture Flyway Diff output to variable flywayDiffs and show output in console

if ($flywayDiffs -like "*no differences detected*") {
  Write-Host "No changes to generate. Exiting script gracefully."
  exit 0  # Graceful exit
} else {
  Write-Host "Changes detected. Proceeding with further steps."
}

# Step 2 - Deploy to target

flyway deploy `
"-environment=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-deploy.scriptFilename=$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME"

# Clean-up: Remove temp artifact files
try {
  Remove-Item "$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME" -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
  } catch {
  Write-Error "Failed to remove temporary artifact files: $_"
  }