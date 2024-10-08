#!/bin/bash

echo "Flyway CLI - Automatic Schema Model Capture"
# FLyway CLI - Global Settings #
REDGATE_FLYWAY_DIFF_VERB="true" # Enables Alpha Diff Verbs within Flyway CLI
export REDGATE_FLYWAY_DIFF_VERB # Exports to Environment Variable (Comment out if already set or not enough permissions)
DIFFERENCE_DETAILS="false" # Set to true to enable enhanced console details for each pending difference
DIFFERENCE_APPLY="true" # Set to true to apply pending changes to target. 

# Flyway CLI - Project Settings # 
flywayProjectName="Westwind" # Optional Project name used within reports and temp file naming
flywayProjectPath="/mnt/c/Redgate/GIT/Repos/AzureDevOps/Westwind" # Ensure flyway.toml is explicitly referenced in filepath
flywayProjectSettings="$flywayProjectPath/flyway.toml"
flywayProjectSchemaModel="$flywayProjectPath/schema-model"
flywayProjectMigrations="$flywayProjectPath/migrations"
flywayVersionDescription="FlywayCLIAutomaticScriptGen" # This will be the description for the Auto-Generated migration script
flywayLicenseKey="FL01404B039A4F4E0AA0943C07036C69D32E234CE5B368E0DC906B1FF4F4D822B118C26BAF5D4FC6657A9BBA5B07FD5DA3E4F89C20D4C32329D76C9FCFAEFD73821D507F7D9DC42C77BF6EBE0E737616AF40CEDA8751B167FC8D11D9B81442AB1F581152839C213774CA55022269B632573CE9105E397AED927630523D0DA476E36F16622ED6FF34ACC92E5F376536F085C54FCACFFFAFF29C338CB8573651219D8623B3712385FC632BFC1B5D230E8B1673C476615B4F48825EADD82F3CC2374BB7C85BB6357CBD30D09D12F44A963918E596B56532AE3C2A895F6978EBB296B327EFF9EE1435283FC059086C85F0FFDB09385EB475779D6E2FF195F3A7E8D1113E"
# Flyway CLI - Environment Details
flywaySourceEnvironment="schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywaySourceJDBC="" # Optional - Leave blank to use Environment settings
flywaySourceUsername="" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywaySourcePassword="" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
flywayTargetEnvironment="Build" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
flywayTargetJDBC="jdbc:sqlserver://127.0.0.1;databaseName=Westwind_Build;encrypt=true;integratedSecurity=false;trustServerCertificate=true" # Optional - Leave blank to use Environment settings
flywayTargetUsername="sa" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
flywayTargetPassword="Redg@te1" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment

diffArtifactFileName="Flyway_${flywayProjectName}_${flywaySourceEnvironment}_differences-$(date +"%d-%m-%Y").zip"
diffArtifactFolder="$flywayProjectPath/Artifacts/$flywayProjectName/"
diffArtifactFilePath="$diffArtifactFolder/$diffArtifactFileName"

echo "Project Path = $flywayProjectPath | Settings are $flywayProjectSettings"

echo "Flyway CLI - Detecting Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"

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

# Show Additional Details Regarding Pending Differences #
if [ $DIFFERENCE_DETAILS = "true" ]; then
    echo "Flyway CLI - Outline Differences between $flywaySourceEnvironment and $flywayTargetEnvironment"
    flyway diffText \
    -diff.artifactFilename="$diffArtifactFilePath" \
    -licenseKey="$flywayLicenseKey" \
    -configFiles="$flywayProjectSettings" \
    -schemaModelLocation="$flywayProjectSchemaModel" || { echo 'Flyway CLI - fiffText Command Failed' ; exit 1; }
else
    echo "Flyway CLI - Skipping Additional Differences Details Due to SHOW_DIFFERENCE_DETAILS variable set to false"
fi

if [ "$DIFFERENCE_APPLY" != "true" ] ; then
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
    echo "Flyway CLI - Skipping Dry Run Script Generation Stage Due to DIFFERENCE_APPLY variable set to false"
fi

if [ "$DIFFERENCE_APPLY" = "true" ] ; then
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
    echo "Flyway CLI - Skipping Deployment Stage Due to DIFFERENCE_APPLY variable set to false"
fi

# Remove Temporary Artifacts #
echo "Clean Up: Deleting temporary artifact files"
rm -r $diffArtifactFolder