$TARGET_ENVIRONMENT = ($null -ne ${env:TARGET_ENVIRONMENT}) ? ${env:TARGET_ENVIRONMENT} : "production"
$TARGET_DATABASE_USERNAME = ($null -ne ${env:TARGET_DATABASE_USERNAME}) ? ${env:TARGET_DATABASE_USERNAME} : "Redgate"
$TARGET_DATABASE_PASSWORD = ($null -ne ${env:TARGET_DATABASE_PASSWORD}) ? ${env:TARGET_DATABASE_PASSWORD} : "Redg@te1"
$BASELINE_VERSION = ($null -ne ${env:BASELINE_VERSION}) ? ${env:BASELINE_VERSION} : "001"
$FLYWAY_LICENSE_KEY = ($null -ne ${env:FLYWAY_LICENSE_KEY}) ? ${env:FLYWAY_LICENSE_KEY} : ""
$FLYWAY_PROJECT_LOCATION = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"
$FLYWAY_PUBLISH = ($null -ne ${env:FLYWAY_PUBLISH}) ? ${env:FLYWAY_PUBLISH} : "true"
$FLYWAY_EMAIL = ($null -ne ${env:FLYWAY_EMAIL}) ? ${env:FLYWAY_EMAIL} : "Chris.Hawkins@red-gate.com"
$FLYWAY_TOKEN = ($null -ne ${env:FLYWAY_TOKEN}) ? ${env:FLYWAY_TOKEN} : "zzw3XaSDtJJfIJOwwrL8cnE3l8vgOVBxjFwGxiV7dEvHNGHyqx6zt5TI02ImBHH7wsCy+sNaBZrb/Py+zRO18w=="

flyway info migrate info `
"-environment=$TARGET_ENVIRONMENT" `
"-user=$TARGET_DATABASE_USERNAME" `
"-password=$TARGET_DATABASE_PASSWORD" `
"-errorOverrides=S0001:0:I-" `
"-baselineOnMigrate=true" `
"-baselineVersion=$BASELINE_VERSION" `
"-licenseKey=$FLYWAY_LICENSE_KEY" `
"-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
"-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
"-publishResult=$FLYWAY_PUBLISH" `
"-flywayServicePublish.publishReport=$FLYWAY_PUBLISH" `
"-reportEnabled=true" `
"-email=$FLYWAY_EMAIL" `
"-token=$FLYWAY_TOKEN"