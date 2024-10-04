# Pipeline Variables #
$flywayClean = ($null -ne ${env:FLYWAY_CLEAN}) ? ${env:env:FLYWAY_CLEAN} : "true"
$flywayMigrate = ($null -ne ${env:FLYWAY_MIGRATE}) ? ${env:env:FLYWAY_MIGRATE} : "true"


# Flyway Variables #
$TARGET_ENVIRONMENT = ($null -ne ${env:TARGET_ENVIRONMENT}) ? ${env:TARGET_ENVIRONMENT} : "build"
$TARGET_DATABASE_JDBC = ($null -ne ${env:TARGET_DATABASE_JDBC}) ? ${env:TARGET_DATABASE_JDBC} : ""
$TARGET_DATABASE_USERNAME = ($null -ne ${env:TARGET_DATABASE_USERNAME}) ? ${env:TARGET_DATABASE_USERNAME} : "Redgate"
$TARGET_DATABASE_PASSWORD = ($null -ne ${env:TARGET_DATABASE_PASSWORD}) ? ${env:TARGET_DATABASE_PASSWORD} : "Redg@te1"
$FLYWAY_LICENSE_KEY = ($null -ne ${env:FLYWAY_LICENSE_KEY}) ? ${env:FLYWAY_LICENSE_KEY} : ""
$FLYWAY_PROJECT_LOCATION = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : "C:\Redgate\GIT\Repos\AzureDevOps\Westwind"

# Validate Scripts Against Target Environment #
if (${flywayClean} -eq "true") {
  try {
      Write-Host "Flyway CLI - Validating Migration Scripts Against $TARGET_ENVIRONMENT"
      flyway info validate `
      "-environment=$TARGET_ENVIRONMENT" `
      "-user=$TARGET_DATABASE_USERNAME" `
      "-password=$TARGET_DATABASE_PASSWORD" `
      "-errorOverrides=S0001:0:I-" `
      "-licenseKey=$FLYWAY_LICENSE_KEY" `
      "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
      "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
      "-ignoreMigrationPatterns=*:pending"
      if ($LASTEXITCODE -ne 0) {
          throw "Flyway CLI - Validation Failed"
      }
    } catch {
      Write-Error "Flyway CLI - Validation Failed. Database Clean Required"
      flyway info clean info `
      "-environment=$TARGET_ENVIRONMENT" `
      "-user=$TARGET_DATABASE_USERNAME" `
      "-password=$TARGET_DATABASE_PASSWORD" `
      "-errorOverrides=S0001:0:I-" `
      "-licenseKey=$FLYWAY_LICENSE_KEY" `
      "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
      "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations" `
      "-cleanDisabled=false"
    }
  }
else {
  Write-Host "Flyway CLI - Skipping Clean Stage Due to FLYWAY_CLEAN variable set to false"
}

if (${flywayMigrate} -eq "true") {
    flyway info migrate info `
    "-environment=$TARGET_ENVIRONMENT" `
    "-user=$TARGET_DATABASE_USERNAME" `
    "-password=$TARGET_DATABASE_PASSWORD" `
    "-errorOverrides=S0001:0:I-" `
    "-licenseKey=$FLYWAY_LICENSE_KEY" `
    "-configFiles=$FLYWAY_PROJECT_LOCATION\flyway.toml" `
    "-locations=filesystem:$FLYWAY_PROJECT_LOCATION\migrations"
  }
else {
  Write-Host "Flyway CLI - Skipping Migrate Stage Due to FLYWAY_MIGRATE variable set to false"
}