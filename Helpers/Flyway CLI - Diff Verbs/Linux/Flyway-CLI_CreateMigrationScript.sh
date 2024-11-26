#!/bin/bash

echo "Flyway CLI - Automatic Schema Model Capture"
# FLyway CLI - Global Settings #
REDGATE_FLYWAY_DIFF_VERB="true" # Enables Alpha Diff Verbs within Flyway CLI
export REDGATE_FLYWAY_DIFF_VERB # Exports to Environment Variable (Comment out if already set or not enough permissions)
DIFFERENCE_DETAILS="true" # Set to true to enable enhanced console details for each pending difference

# Flyway CLI - Project Settings # 
flywayProjectName="Westwind" # Optional Project name used within reports and temp file naming
flywayProjectPath="/mnt/c/Redgate/GIT/Repos/AzureDevOps/Westwind" # Ensure flyway.toml is explicitly referenced in filepath
flywayProjectSettings="$flywayProjectPath/flyway.toml"
flywayProjectSchemaModel="$flywayProjectPath/schema-model"
flywayProjectMigrations="$flywayProjectPath/migrations"
flywayVersionDescription="FlywayCLIAutomaticScriptGen" # This will be the description for the Auto-Generated migration script
### Flyway Auth Settings ###
FLYWAY_EMAIL=""
FLYWAY_TOKEN=""
# Flyway CLI - Environment Details
flywaySourceEnvironment="schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywaySourceJDBC="" # Optional - Leave blank to use Environment settings
flywaySourceUsername="" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywaySourcePassword="" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
flywayTargetEnvironment="migrations" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayTargetJDBC="" # Optional - Leave blank to use Environment settings
flywayTargetUsername="" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayTargetPassword="" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the 
flywayBuildEnvironment="shadow" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayBuildJDBC="jdbc:sqlserver://127.0.0.1;databaseName=Westwind_Build;encrypt=true;integratedSecurity=false;trustServerCertificate=true" # Optional - Leave blank to use Environment settings
flywayBuildUsername="sa" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayBuildPassword="Redg@te1" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment

diffArtifactFileName="Flyway_${flywayProjectName}_${flywaySourceEnvironment}_differences-$(date +"%d-%m-%Y").zip"
diffArtifactFolder="$flywayProjectPath/Artifacts/$flywayProjectName/"
diffArtifactFilePath="$diffArtifactFolder/$diffArtifactFileName"

echo "Project Path = $flywayProjectPath | Settings are $flywayProjectSettings"

echo "Flyway CLI - Detect Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"

diffList=$(flyway diff \
    -diff.source="$flywaySourceEnvironment" \
    -diff.target="$flywayTargetEnvironment" \
    -diff.buildEnvironment="$flywayBuildEnvironment" \
    -environments.$flywayBuildEnvironment.url="$flywayBuildJDBC" \
    -environments.$flywayBuildEnvironment.user="$flywayBuildUsername" \
    -environments.$flywayBuildEnvironment.password="$flywayBuildPassword" \
    -diff.artifactFilename="$diffArtifactFilePath" \
    -outputType="" \
    -email="$FLYWAY_EMAIL" \
    -token="$FLYWAY_TOKEN" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" \
    -locations=filesystem:"$flywayProjectMigrations") || { 
        echo 'Flyway CLI - Diff Command Failed'
        exit 1 
    }

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

# Show Additional Details Regarding Pending Differences #
if [ "$DIFFERENCE_DETAILS" = "true" ]; then
    echo "Flyway CLI - Outline Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"
    flyway diffText \
    -diff.artifactFilename="$diffArtifactFilePath" \
    -licenseKey="$flywayLicenseKey" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - fiffText Command Failed' ; exit 1; }
else
    echo "Flyway CLI - Skipping Additional Differences Details Due to SHOW_DIFFERENCE_DETAILS variable set to false"
fi

echo "Flyway CLI - Generate Deployment Script For: $flywayTargetEnvironment"

flyway generate \
-generate.description="$flywayVersionDescription" \
-generate.location="$flywayProjectMigrations" \
-generate.types="versioned,undo" \
-generate.artifactFilename="$diffArtifactFilePath" \
-generate.addTimestamp="true" \
-outputType="" \
-generate.force="true" \
-licenseKey="$flywayLicenseKey" \
-configFiles="$flywayProjectSettings" \
-schemaModelLocation="$flywayProjectSchemaModel" \
-locations=filesystem:"$flywayProjectMigrations" || { echo 'Flyway CLI - Generate Command Failed' ; exit 1; }

# Remove Temporary Artifacts #
echo "Clean Up: Deleting temporary artifact files"
rm -r $diffArtifactFolder