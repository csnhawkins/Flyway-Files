# dbatools MODULE NEEDED
if (!(Get-Module -ListAvailable -Name dbatools)) {
  Write-Host "dbatools module not found. Installing module..."
  # Install the dbatools module
  Install-Module -Name dbatools -Force -AllowClobber
  Write-Host "dbatools module installed successfully."
} else {
  Write-Host "dbatools module is already installed."
}
# Prompt for input
if (!($projectDir = Read-Host "Enter the top level local GIT folder location: (Leave Blank for Default Value: C:\WorkingFolders\FWD)")) { $projectDir = "C:\WorkingFolders\FWD" }
if (!($serverName = Read-Host "Enter the SQL Server name (Leave Blank for Default Value: Localhost)")) { $serverName = "Localhost" }

do {
  $trustCert = Read-Host "Do we need to trust the Server Certificate [Y] or [N]?"
  $trustCert = $trustCert.ToUpper()  # Convert the input to uppercase
  $trustCertBoolean = ($trustCert -eq 'Y') ? "true" : "false"
}
until ($trustCert -eq 'Y' -or $trustCert -eq 'N')  # Proper comparison
do {
  $encryptConnection = Read-Host "Do we need to encrypt the connection [Y] or [N]?"
  $encryptConnection = $trustCert.ToUpper()  # Convert the input to uppercase
  $encryptConnectionBoolean = ($encryptConnection -eq 'Y') ? "true" : "false"
}
until ($trustCert -eq 'Y' -or $trustCert -eq 'N')  # Proper comparison
#Block to generate connection string
if ($trustCert -eq 'Y' -and $encryptConnection -eq 'Y')
{
$SqlConnection = Connect-DbaInstance -SqlInstance $serverName -TrustServerCertificate -EncryptConnection
}
if ($trustCert -eq 'Y' -and $encryptConnection -eq 'N')
{
$SqlConnection = Connect-DbaInstance -SqlInstance $serverName -TrustServerCertificate
}
if ($trustCert -eq 'N' -and $encryptConnection -eq 'Y')
{
$SqlConnection = Connect-DbaInstance -SqlInstance $serverName -EncryptConnection
}
if ($trustCert -eq 'N' -and $encryptConnection -eq 'N')
{
$SqlConnection = Connect-DbaInstance -SqlInstance $serverName
}
$coreDBList = @(
  'Aardvark',
  'NewWorldDB',
  'Northwind'
)
foreach ($coreDB in $coreDBList)
{
Write-Host "### Flyway CLI - Development Database Sync - $coreDB ###"

### Variables ###
$PROJECT_DIRECTORY = "$projectDir\$coreDB"
$ARTIFACT_DIRECTORY = "$PROJECT_DIRECTORY\deployments"
$SCRIPT_FILENAME = "FlywayCLI_$coreDB_deploymentscript_$(get-date -f yyyyMMdd).sql"
$DATABASE_NAME = $coreDB + '_Dev'
$TARGET_ENVIRONMENT = "development"
$TARGET_DATABASE_JDBC = "jdbc:sqlserver://$serverName;databaseName=$DATABASE_NAME;encrypt=$encryptConnectionBoolean;integratedSecurity=$TARGET_DATABAE_INTEGRATED_SECURITY;trustServerCertificate=$trustCertBoolean"
$TARGET_DATABAE_INTEGRATED_SECURITY = "true"
$TARGET_DATABASE_USERNAME = ""
$TARGET_DATABASE_PASSWORD = ""
###



Set-Location $PROJECT_DIRECTORY
Write-Host "Creating database $coreDB within $serverName if required"
$CreateDB = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$DATABASE_NAME')
BEGIN
CREATE DATABASE $DATABASE_NAME;
END;
GO
"@
Invoke-DbaQuery -Query $CreateDB -SqlInstance $sqlConnection
Write-Host "Flyway CLI - Detecting differences between schemaModel & $coreDB"
flyway prepare "-prepare.source=schemaModel" "-prepare.target=$TARGET_ENVIRONMENT" "-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" "-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USERNAME" "-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" "-schemaModelLocation=$projectDir\$coreDB\schema-model" "-prepare.scriptFilename=$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME" "-configFiles=$PROJECT_DIRECTORY\flyway.toml" | Tee-Object -Variable flywayDiffs

# Check if the previous command was successful
if ($? -eq $false) {
  Write-Error "Flyway CLI - Prepare Command Failed. Exiting Session"
  exit 2  # Custom exit code to indicate a failure in the difference check command
}
# Check for "No differences found" in the result
if ($flywayDiffs -match "No script generated") {
  Write-Output "Flyway CLI - No Differences Found. Script Completed."
} else {
  Write-Output "Flyway CLI - Differences Found: Continuing to apply differences"
  Write-Output "Flyway CLI - Deploying Changes to: $coreDB"
  flyway deploy "-environment=$TARGET_ENVIRONMENT" "-environments.$TARGET_ENVIRONMENT.url=$TARGET_DATABASE_JDBC" "-environments.$TARGET_ENVIRONMENT.user=$TARGET_DATABASE_USERNAME" "-environments.$TARGET_ENVIRONMENT.password=$TARGET_DATABASE_PASSWORD" "-deploy.scriptFilename=$ARTIFACT_DIRECTORY\$SCRIPT_FILENAME" "-configFiles=$PROJECT_DIRECTORY\flyway.toml"

  # Clean-up: Remove temp artifact files
  try {
  Remove-Item $ARTIFACT_DIRECTORY -Recurse -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
       } catch {
      Write-Error "Failed to remove temporary artifact files: $_"
  }
}
}