#!/bin/bash
echo "Flyway CLI - Automatic Schema Model Capture"
# FLyway CLI - Global Settings #
# To assist with script validation, parameter expansions have been used for important variables. For example: ${VARNAME:-DefaultValue}
# This means that the variable is first attempted to be set with VARNAME, which if not found defaults to the value specified after :-
DEPLOY_DIFFERENCES="${DEPLOY_DIFFERENCES:-true}" # Variable to determine if the change should be deployed or not. Uses environment variable and if not found will default to NOTSET
# Flyway CLI - Project Settings # 
flywayProjectName="${FLYWAY_PROJECT_NAME:-MyFlywayProject}" # Optional Project name used within reports and temp file naming
flywayProjectPath="${WORKING_DIRECTORY:-/mnt/c/Redgate/GIT/Repos/AzureDevOps/Westwind}" # Ensure flyway.toml is explicitly referenced in filepath
flywayProjectSettings="$flywayProjectPath/flyway.toml"
flywayProjectSchemaModel="$flywayProjectPath/schema-model"
flywayProjectMigrations="$flywayProjectPath/migrations"
flywayVersionDescription="${FLYWAY_VERSION_DESCRIPTION:-FlywayCLIAutomatedScript}" # This will be the description for the Auto-Generated migration script
### Flyway Auth Settings ###
FLYWAY_EMAIL="${FLYWAY_EMAIL:-MyRedgateEmail@email.com}"
FLYWAY_TOKEN="${FLYWAY_TOKEN:-MySecureTokenGoesHere}"
# Flyway CLI - Environment Details
flywaySourceEnvironment="${SOURCE_ENVIRONMENT:-schemaModel}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywaySourceJDBC="${SOURCE_JDBC:-}" # Optional - Leave blank to use Environment settings
flywaySourceUsername="${SOURCE_DATABASE_USERNAME:-MyDefaultUsername}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywaySourcePassword="${SOURCE_DATABASE_PASSWORD:-MyDefaultPassword}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
flywayTargetEnvironment="${TARGET_ENVIRONMENT:-Test}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayTargetJDBC="${TARGET_JDBC:-jdbc:sqlserver://127.0.0.1;databaseName=Westwind_Build;encrypt=true;integratedSecurity=false;trustServerCertificate=true}" # Optional - Leave blank to use Environment settings
flywayTargetUsername="${TARGET_DATABASE_USERNAME:-sa}" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayTargetPassword="${TARGET_DATABASE_PASSWORD:-Redg@te1}" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
diffArtifactFileName="Flyway_${flywayProjectName}_${flywaySourceEnvironment}_differences-$(date +"%d-%m-%Y").sql"
diffArtifactFolder="$flywayProjectPath/Artifacts/$flywayProjectName/"
diffArtifactFilePath="$diffArtifactFolder/$diffArtifactFileName"
echo "Project Path = $flywayProjectPath | Settings are $flywayProjectSettings"
echo "Flyway CLI - Detecting Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"
echo "Current Working Directory Is: $(pwd)"
echo "Files in current folder are:\n$(ls)"
diffList=$(flyway prepare \
    -prepare.source="$flywaySourceEnvironment" \
    -prepare.target="$flywayTargetEnvironment" \
    -environments.$flywayTargetEnvironment.url="$flywayTargetJDBC" \
    -environments.$flywayTargetEnvironment.user="$flywayTargetUsername" \
    -environments.$flywayTargetEnvironment.password="$flywayTargetPassword" \
    -prepare.scriptFilename="$diffArtifactFilePath" \
    -prepare.force="true" \
    -email="$FLYWAY_EMAIL" \
    -token="$FLYWAY_TOKEN" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel") || {
     echo 'Flyway CLI - Diff Command Failed'
     exit 1 
    }

echo "$diffList"

echo "Script Validation - Check if any differences found"

# Run the flyway command and check for "No differences found"
if echo "$diffList" | grep -q "no differences detected"; then
    echo "No differences detected, stopping script."
    exit 0  # Stop the script
else
    echo "Differences found, continuing script."
    # Continue with the rest of your script
fi

if [ "$DEPLOY_DIFFERENCES" = "true" ] ; then
    echo "Flyway CLI - Deploy Differences to Target Environment: $flywayTargetEnvironment"
    flyway deploy \
    -environment="$flywayTargetEnvironment" \
    -environments.$flywayTargetEnvironment.url="$flywayTargetJDBC" \
    -environments.$flywayTargetEnvironment.user="$flywayTargetUsername" \
    -environments.$flywayTargetEnvironment.password="$flywayTargetPassword" \
    -deploy.scriptFilename="$diffArtifactFilePath" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { 
        echo 'Flyway CLI - Deploy Command Failed'
        exit 1 
    }
else
    echo "Flyway CLI - Skipping Deployment Stage Due to DEPLOY_DIFFERENCES variable set to false"
fi

# Remove Temporary Artifacts #
echo "Clean Up: Deleting temporary artifact files"
rm -r $diffArtifactFolder