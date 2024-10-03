#!/bin/bash

echo "Flyway CLI - Automatic Schema Model Capture"
# FLyway CLI - Global Settings #
REDGATE_FLYWAY_DIFF_VERB="${REDGATE_FLYWAY_DIFF_VERB:-true}" # Enables Alpha Diff Verbs within Flyway CLI
export REDGATE_FLYWAY_DIFF_VERB # Exports to Environment Variable (Comment out if already set or not enough permissions)
DEPLOY_DIFFERENCES="${DEPLOY_DIFFERENCES:-NOT SET}" # Variable to determine if the change should be deployed or not. Uses environment variable and if not found will default to NOTSET

# Flyway CLI - Project Settings # 
flywayProjectName="${FLYWAY_PROJECT_NAME:-MyFlywayProject}" # Optional Project name used within reports and temp file naming
flywayProjectPath="$WORKING_DIRECTORY" # Ensure flyway.toml is explicitly referenced in filepath
flywayProjectSettings="$flywayProjectPath/flyway.toml"
flywayProjectSchemaModel="$flywayProjectPath/schema-model"
flywayProjectMigrations="$flywayProjectPath/migrations"
flywayVersionDescription="${FLYWAY_VERSION_DESCRIPTION:-FlywayCLIAutomatedScript}" # This will be the description for the Auto-Generated migration script
flywayLicenseKey="$FLYWAY_LICENSE_KEY"
# Flyway CLI - Environment Details
flywaySourceEnvironment="${SOURCE_ENVIRONMENT:-schemaModel}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywaySourceJDBC="$SOURCE_JDBC" # Optional - Leave blank to use Environment settings
flywaySourceUsername="$SOURCE_DATABASE_USERNAME" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywaySourcePassword="$SOURCE_DATABASE_PASSWORD" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
flywayTargetEnvironment="${TARGET_ENVIRONMENT:-Test}" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayTargetJDBC="$TARGET_JDBC" # Optional - Leave blank to use Environment settings
flywayTargetUsername="$TARGET_DATABASE_USERNAME" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayTargetPassword="$TARGET_DATABASE_PASSWORD" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment

diffArtifactFileName="Flyway_${flywayProjectName}_${flywaySourceEnvironment}_differences-$(date +"%d-%m-%Y").zip"
diffArtifactFolder="$flywayProjectPath/Artifacts/$flywayProjectName/"
diffArtifactFilePath="$diffArtifactFolder/$diffArtifactFileName"

echo "Project Path = $flywayProjectPath | Settings are $flywayProjectSettings"

echo "Flyway CLI - Detecting Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"

echo "Current Working Directory Is: $(pwd)"
echo "Files in current folder are:\n$(ls)"

diffList=$(flyway diff \
-diff.source="$flywaySourceEnvironment" \
-diff.target="$flywayTargetEnvironment" \
-environments.$flywayTargetEnvironment.url="$flywayTargetJDBC" \
-environments.$flywayTargetEnvironment.user="$flywayTargetUsername" \
-environments.$flywayTargetEnvironment.password="$flywayTargetPassword" \
-diff.artifactFilename="$diffArtifactFilePath" \
-outputType="" \
-licenseKey="$flywayLicenseKey" \
-configFiles="$flywayProjectSettings" \
-schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - Diff Command Failed' ; exit 1; })

echo "$diffList"

echo "Script Validation - Check if any differences found"

# Run the flyway command and check for "No differences found"
if echo "$diffList" | grep -q "No differences found"; then
    echo "No differences found, stopping script."
    # Remove Temporary Artifacts #
    echo "Clean Up: Deleting temporary artifact files"
    rm -r $diffArtifactFolder
    exit 0  # Stop the script
else
    echo "Differences found, continuing script."
    # Continue with the rest of your script
fi

# Generate Dry Run Script for pending differences (Can be skipped if doing a deployment)

if [ "$DEPLOY_DIFFERENCES" != "true" ] ; then
    echo "Flyway CLI - Generate Deployment Script For: $flywayTargetEnvironment"
    flyway generate \
    -generate.description="$flywayVersionDescription" \
    -generate.location="$flywayProjectPath/Artifacts/" \
    -generate.types="versioned,undo" \
    -generate.artifactFilename="$diffArtifactFilePath" \
    -outputType="" \
    -generate.force="true" \
    -licenseKey="$flywayLicenseKey" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - Generate Command Failed' ; exit 1; }
else
    echo "Flyway - CLI - Skipping Dry Run Script Generation Stage Due to DEPLOY_DIFFERENCES variable set to false"
fi

# Deploying differences to target environment #

if [ "$DEPLOY_DIFFERENCES" = "true" ]; then
    echo "Flyway CLI - Apply Differences to Target Environment: $flywayTargetEnvironment"
    flyway diffApply \
    -diffApply.target="$flywayTargetEnvironment" \
    -environments.$flywayTargetEnvironment.url="$flywayTargetJDBC" \
    -environments.$flywayTargetEnvironment.user="$flywayTargetUsername" \
    -environments.$flywayTargetEnvironment.password="$flywayTargetPassword" \
    -diffApply.artifactFilename="$diffArtifactFilePath" \
    -outputType="" \
    -licenseKey="$flywayLicenseKey" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - diffApply Command Failed' ; exit 1; }
else
    echo "Flyway CLI - Skipping Deployment Stage Due to DEPLOY_DIFFERENCES variable set to false"
fi

# Remove Temporary Artifacts - Disabled By Default, so that Pipeline tool can publish files as artifact #
# echo "Clean Up: Deleting temporary artifact files"
# rm -r $diffArtifactFolder