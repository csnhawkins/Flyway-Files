# Flyway Variables #
$TARGET_ENVIRONMENT = ($null -ne ${env:TARGET_ENVIRONMENT}) ? ${env:TARGET_ENVIRONMENT} : "Build"
$TARGET_DATABASE_JDBC = ($null -ne ${env:TARGET_DATABASE_JDBC}) ? ${env:TARGET_DATABASE_JDBC} : ""
$TARGET_DATABASE_USERNAME = ($null -ne ${env:TARGET_DATABASE_USERNAME}) ? ${env:TARGET_DATABASE_USERNAME} : "Redgate"
$TARGET_DATABASE_PASSWORD = ($null -ne ${env:TARGET_DATABASE_PASSWORD}) ? ${env:TARGET_DATABASE_PASSWORD} : "Redg@te1"
$FLYWAY_LICENSE_KEY = ($null -ne ${env:FLYWAY_LICENSE_KEY}) ? ${env:FLYWAY_LICENSE_KEY} : ""
$FLYWAY_PROJECT_LOCATION = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : "C:\Redgate\GIT\Repos\GitHub\AutoPilot-Development\Flyway-AutoPilot-FastTrack_Forked"

# Optional - Flyway Pipeline #
$FLYWAY_PUBLISH_RESULT = ($null -ne ${env:FLYWAY_PUBLISH_RESULT}) ? ${env:FLYWAY_PUBLISH_RESULT} : "false"
$FLYWAY_PIPELINES_EMAIL = ($null -ne ${env:FLYWAY_PIPELINES_EMAIL}) ? ${env:FLYWAY_PIPELINES_EMAIL} : "NOTSET"
$FLYWAY_PIPELINES_TOKEN = ($null -ne ${env:FLYWAY_PIPELINES_TOKEN}) ? ${env:FLYWAY_PIPELINES_TOKEN} : "NOTSET"

# Validate Scripts Against Target Environment #
Write-Host "$(Get-Date) - Flyway CLI - Validating Migration Scripts Against $TARGET_ENVIRONMENT"
flyway validate `
    "-environment=$TARGET_ENVIRONMENT" `
    "-user=$TARGET_DATABASE_USERNAME" `
    "-password=$TARGET_DATABASE_PASSWORD" `
    "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
    "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
    "-ignoreMigrationPatterns=*:pending"

if ($LASTEXITCODE -ne 0) {
    Write-Host "$(Get-Date) - Validation Failed. Running Flyway Clean."
    flyway clean `
        "-environment=$TARGET_ENVIRONMENT" `
        "-user=$TARGET_DATABASE_USERNAME" `
        "-password=$TARGET_DATABASE_PASSWORD" `
        "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
        "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
        "-cleanDisabled=false"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "$(Get-Date) - Clean Failed. Exiting."
        exit $LASTEXITCODE
    }
    Write-Host "$(Get-Date) - Clean Completed Successfully."
} else {
    Write-Host "$(Get-Date) - Validation Completed Successfully."
}

Write-Host "$(Get-Date) - Running Flyway Migrate."
flyway migrate `
    "-environment=$TARGET_ENVIRONMENT" `
    "-user=$TARGET_DATABASE_USERNAME" `
    "-password=$TARGET_DATABASE_PASSWORD" `
    "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
    "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations"

if ($LASTEXITCODE -ne 0) {
    Write-Host "$(Get-Date) - Migration Failed. Exiting."
    exit $LASTEXITCODE
}

Write-Host "$(Get-Date) - Migration Completed Successfully."

# Deprecated - Validate and Migrate Scripts Against Target Environment (Emptying target DB where necessary)#

# flyway info validate migrate info `
# "-environment=$TARGET_ENVIRONMENT" `
# "-user=$TARGET_DATABASE_USERNAME" `
# "-password=$TARGET_DATABASE_PASSWORD" `
# "-errorOverrides=S0001:0:I-" `
# "-licenseKey=$FLYWAY_LICENSE_KEY" `
# "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
# "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
# "-flywayServicePublish.publishReport=$FLYWAY_PUBLISH_RESULT" `
# "-reportEnabled=$FLYWAY_PUBLISH_RESULT" `
# "-email=$FLYWAY_PIPELINES_EMAIL" `
# "-token=$FLYWAY_PIPELINES_TOKEN" `
# "-cleanOnValidationError=true" `
# "-cleanDisabled=false"