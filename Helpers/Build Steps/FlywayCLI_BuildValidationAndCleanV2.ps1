# Flyway Variables #
$TARGET_ENVIRONMENT = ($null -ne ${env:TARGET_ENVIRONMENT}) ? ${env:TARGET_ENVIRONMENT} : "Build"
$TARGET_DATABASE_JDBC = ($null -ne ${env:TARGET_DATABASE_JDBC}) ? ${env:TARGET_DATABASE_JDBC} : ""
$TARGET_DATABASE_USERNAME = ($null -ne ${env:TARGET_DATABASE_USERNAME}) ? ${env:TARGET_DATABASE_USERNAME} : "Redgate"
$TARGET_DATABASE_PASSWORD = ($null -ne ${env:TARGET_DATABASE_PASSWORD}) ? ${env:TARGET_DATABASE_PASSWORD} : "Redg@te1"
$FLYWAY_LICENSE_KEY = ($null -ne ${env:FLYWAY_LICENSE_KEY}) ? ${env:FLYWAY_LICENSE_KEY} : ""
$FLYWAY_PROJECT_LOCATION = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"

# Optional - Flyway Pipeline #
$FLYWAY_PUBLISH_RESULT = ($null -ne ${env:FLYWAY_PUBLISH_RESULT}) ? ${env:FLYWAY_PUBLISH_RESULT} : "false"
$FLYWAY_PIPELINES_EMAIL = ($null -ne ${env:FLYWAY_PIPELINES_EMAIL}) ? ${env:FLYWAY_PIPELINES_EMAIL} : "NOTSET"
$FLYWAY_PIPELINES_TOKEN = ($null -ne ${env:FLYWAY_PIPELINES_TOKEN}) ? ${env:FLYWAY_PIPELINES_TOKEN} : "NOTSET"


# Validate and Migrate Scripts Against Target Environment (Emptying target DB where necessary)#

    flyway info validate migrate info `
    "-environment=$TARGET_ENVIRONMENT" `
    "-user=$TARGET_DATABASE_USERNAME" `
    "-password=$TARGET_DATABASE_PASSWORD" `
    "-errorOverrides=S0001:0:I-" `
    "-licenseKey=$FLYWAY_LICENSE_KEY" `
    "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
    "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
    "-flywayServicePublish.publishReport=$FLYWAY_PUBLISH_RESULT" `
    "-reportEnabled=$FLYWAY_PUBLISH_RESULT" `
    "-email=$FLYWAY_PIPELINES_EMAIL" `
    "-token=$FLYWAY_PIPELINES_TOKEN" `
    "-cleanOnValidationError=true" `
    "-cleanDisabled=false"