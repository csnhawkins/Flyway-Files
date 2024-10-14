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

$FLYWAY_LICENSE_KEY = ""
$WORKING_DIRECTORY = "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"

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
"-diff.artifactFilename=C:\Redgate\GIT\Repos\AzureDevOps\Westwind\Artifacts\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
-outputType="" `
-licenseKey="$FLYWAY_LICENSE_KEY" `
-configFiles="$WORKING_DIRECTORY\flyway.toml" `
-schemaModelLocation="$WORKING_DIRECTORY\schema-model\"

# Step 2 - Prepare Deployment Script

flyway prepare `
"-prepare.changes=" `
"-prepare.artifactFilename=C:\Redgate\GIT\Repos\AzureDevOps\Westwind\Artifacts\Flyway.$DATABASE_NAME.differences-$(get-date -f yyyyMMdd).zip" `
"-deployScript=C:\Redgate\GIT\Repos\AzureDevOps\Westwind\Artifacts\Flyway-$DATABASE_NAME-AutoDeploymentScript-$(get-date -f yyyyMMdd).sql"

flyway generate `
"-generate.description=$flywayVersionDescription" `
"-generate.location=$flywayProjectPath/Artifacts/" `
"-generate.types=versioned,undo" `
"-generate.artifactFilename=$diffArtifactFilePath" `
"-outputType=" `
"-generate.force=true" `
"-licenseKey=$flywayLicenseKey" `
"-configFiles=$flywayProjectSettings" `
"-schemaModelLocation=$flywayProjectSchemaModel"

# Step 3 - Deploy to target

flyway deploy `
"-environment=$TARGET_ENVIRONMENT" `
"-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" `
"-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USER" `
"-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" `
"-deployScript=C:\Redgate\GIT\Repos\AzureDevOps\Westwind\Artifacts\Flyway-$DATABASE_NAME-AutoDeploymentScript-$(get-date -f yyyyMMdd).sql"
