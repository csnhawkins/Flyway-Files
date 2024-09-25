
# Specify the paths to the Flyway Project and Configuration files

$flywayProjectPath = "C:\WorkingFolders\FWD\NewWorldDB" # Ensure flyway.toml is explicitly referenced in filepath
$flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
$flywayProjectMigrationPath = Join-Path $flywayProjectPath "Migrations"
$flywayMigrationScriptDescription = "FlywayDev_AutomatedScriptGen" # This will be the description within each migration script

# Define temporary diff file and path
$tempFilePath = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\comparison_artifacts_SchemaModel_Migrations"
$diffArtifactFileName = New-Guid 
$null = New-Item -ItemType Directory -Force -Path $tempFilePath
$diffArtifactFilePath = Join-Path $tempFilePath  $diffArtifactFileName

# Parameters for Flyway dev
$commonParams =
@("--artifact=$diffArtifactFilePath",
"--project=$flywayProjectSettings",
"--i-agree-to-the-eula")

$diffParams = @("diff", "--from=SchemaModel", "--to=Migrations") + $commonParams
$migrationScriptNameParams = @("next-migration-name", "--description=$flywayMigrationScriptDescription", "--increment=Patch", "--output=json", "--project=$flywayProjectSettings", "--i-agree-to-the-eula")
$generateParams = @("generate", "--name=$NextVersionedMigrationScriptName", "--outputFolder=$flywayProjectMigrationPath", "--changes", "-")+ $commonParams
$takeParams = @("take") + $commonParams


# Flyway-Dev: Detect all changes from Schema Model
flyway-dev @diffParams

# Flyway-Dev: Find out next migration script name
$NextMigrationScriptName = flyway-dev $migrationScriptNameParams | ConvertFrom-Json 
$NextVersionedMigrationScriptName = $NextMigrationScriptName.versionedIdentifier
Write-Host "The next Version Number will be $NextVersionedMigrationScriptName"

#Flyway-Dev: Select changes and create migration script
flyway-dev @takeParams | flyway-dev @generateParams

# Clean-up: Remove temp artifact files
Remove-Item $diffArtifactFilePath