#!/bin/bash

echo "Flyway CLI - Automatic Schema Model Capture"

REDGATE_FLYWAY_DIFF_VERB="true" # Enables Alpha Diff Verbs within Flyway CLI
export REDGATE_FLYWAY_DIFF_VERB # Exports to Environment Variable
DIFFERENCE_DETAILS="false" # Set to true to enable enhanced console details for each pending difference
DIFFERENCE_APPLY="true" # Set to true to apply pending changes to target. 
### Flyway Project Settings ###
flywayProjectPath="/mnt/c/Redgate/GIT/Repos/AzureDevOps/Westwind" # Ensure flyway.toml is explicitly referenced in filepath
flywayProjectSettings="$flywayProjectPath/flyway.toml"
flywayProjectSchemaModel="$flywayProjectPath/schema-model"
flywayProjectMigrations="$flywayProjectPath/migrations"
flywayVersionDescription="FlywayCLIAutomaticScriptGen" # This will be the description for the Auto-Generated migration script
### Flyway Auth Settings ###
FLYWAY_EMAIL=""
FLYWAY_TOKEN=""
# Optional - Environment Details
flywaySourceEnvironment="development" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywaySourceJDBC="jdbc:sqlserver://127.0.0.1;databaseName=Westwind_Dev;encrypt=true;integratedSecurity=false;trustServerCertificate=true" # Optional - Leave blank to use Environment settings
flywaySourceUsername="sa" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywaySourcePassword="Redg@te1" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
flywayTargetEnvironment="schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayTargetJDBC="" # Optional - Leave blank to use Environment settings
flywayTargetUsername="" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayTargetPassword="" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
### Artifact Location ###
diffArtifactFileName="Flyway_${flywayProjectName}_${flywaySourceEnvironment}_differences-$(date +"%d-%m-%Y").zip"
diffArtifactFolder="$flywayProjectPath/Artifacts/$flywayProjectName/"
diffArtifactFilePath="$diffArtifactFolder/$diffArtifactFileName"

echo "Project Path = $flywayProjectPath | Settings are $flywayProjectSettings"

echo "Flyway CLI - Detect Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"

diffList=$(flyway diff \
    -diff.source="$flywaySourceEnvironment" \
    -environments.$flywaySourceEnvironment.url="$flywaySourceJDBC" \
    -environments.$flywaySourceEnvironment.user="$flywaySourceUsername" \
    -environments.$flywaySourceEnvironment.password="$flywaySourcePassword" \
    -diff.target="$flywayTargetEnvironment" \
    -environments.$flywayTargetEnvironment.user="$flywayTargetUsername" \
    -environments.$flywayTargetEnvironment.password="$flywayTargetPassword" \
    -diff.artifactFilename="$diffArtifactFilePath" \
    -email="$FLYWAY_EMAIL" \
    -token="$FLYWAY_TOKEN" \
    -outputType="" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel") || { 
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
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - DiffText Command Failed' ; exit 1; }
else
    echo "Flyway CLI - Skipping Additional Differences Details Due to SHOW_DIFFERENCE_DETAILS variable set to false"
fi

# Deploying differences to target environment #
if [ "$DIFFERENCE_APPLY" = "true" ]; then
    echo "Flyway CLI - Apply Differences to Schema Model"
    flyway model \
    -model.artifactFilename="$diffArtifactFilePath" \
    -outputType="" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - Model Command Failed' ; exit 1; }
else
    echo "Flyway CLI - Skipping Deployment Stage Due to DEPLOY_DIFFERENCES variable set to false"
fi

# Remove Temporary Artifacts #
echo "Clean Up: Deleting temporary artifact files"
rm -r $diffArtifactFolder