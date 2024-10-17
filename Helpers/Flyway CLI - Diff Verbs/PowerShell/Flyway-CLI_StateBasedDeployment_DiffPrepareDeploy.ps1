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
$ARTIFACT_DIRECTORY = "$WORKING_DIRECTORY\Artifacts"
$SCRIPT_FILENAME = "Flyway-$DATABASE_NAME-AutoDeploymentScript-$(get-date -f yyyyMMdd).sql"

# Pre-Step (Optional) - Create Diff Artifact

# flyway diff `
# "-diff.source=$SOURCE_ENVIRONMENT" `
# "-environments.$SOURCE_ENVIRONMENT.url=$SOURCE_DATABASE_JDBC" `
# "-environments.$SOURCE_ENVIRONMENT.user=$SOURCE_DATABASE_USER" `
# "-environments.$SOURCE_ENVIRONMENT.password=$SOURCE_DATABASE_PASSWORD" `
# "-diff.target=$TARGET_ENVIRONMENT" `
# "-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
# "-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
# "-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
# "-diff.artifactFilename=$ARTIFACT_DIRECTORY\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
# -outputType="" `
# -licenseKey="$FLYWAY_LICENSE_KEY" `
# -configFiles="$WORKING_DIRECTORY\flyway.toml" `
# -schemaModelLocation="$WORKING_DIRECTORY\schema-model\" `
# -email="$FLYWAY_EMAIL" `
# -token="$FLYWAY_TOKEN"
# | Tee-Object -Variable flywayDiffs  # Capture Flyway Diff output to variable flywayDiffs and show output in console

# if ($flywayDiffs -like "*No differences found*") {
#   Write-Host "No changes to generate. Exiting script gracefully."
#   exit 0  # Graceful exit
# } else {
#   Write-Host "Changes detected. Proceeding with further steps."
# }

# Step 2a - Prepare: Consume Diff Artifact and Create Deployment SCript

# flyway prepare `
# "-prepare.changes=" `
# "-prepare.artifactFilename=$ARTIFACT_DIRECTORY\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
# "-deployScript=$ARTIFACT_DIRECTORY\Flyway-$DATABASE_NAME-AutoDeploymentScript-$(get-date -f yyyyMMdd).sql" `
# -email="$FLYWAY_EMAIL" `
# -token="$FLYWAY_TOKEN"

# Step 2b - Prepare: Detect differences and create deployment script
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
-email="$FLYWAY_EMAIL" `
-token="$FLYWAY_TOKEN"

# Step 3 - Deploy to target

flyway deploy `
"-environment=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-deploy.scriptFilename=$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME"