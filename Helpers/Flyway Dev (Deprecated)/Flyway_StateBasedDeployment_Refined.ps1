Set-StrictMode -Version Latest

# Specify the paths to the Flyway Project and Configuration files
$flywayProjectPath = "C:\WorkingFolders\FWD\NewWorldDB_State"
$flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"

# Target Database Connection Details
$targetJDBC = "jdbc:sqlserver://localhost;databaseName=newworlddb_test;encrypt=false;integratedSecurity=true;trustServerCertificate=true"
$targetUser = "Redgate"
$targetPassword = "Redgate"

# Define temporary diff file and path
$diffArtifactFileName = [guid]::NewGuid().ToString()
$tempFilePath = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\comparison_artifacts_Dev_SchemaModel"

if (-not (Test-Path $tempFilePath)) {
    New-Item -ItemType Directory -Force -Path $tempFilePath | Out-Null
}

$diffArtifactFilePath = Join-Path $tempFilePath $diffArtifactFileName

# Parameters for Flyway dev
$commonParams = @("--artifact=$diffArtifactFilePath", "--project=$flywayProjectSettings", "--i-agree-to-the-eula")
$diffParams = @("diff", "--from=SchemaModel", "--to=Target") + $commonParams

# Target Connection Details passed as JSON to Flyway-Dev
$targetConnectionString = "{`"id`":`"temp`",`"url`":`"$targetJDBC`",`"user`":`"$targetUser`",`"password`":`"$targetPassword`",`"schemas`":[],`"resolverProperties`":[],`"jdbcProperties`":{}}"

# Step 1: Calculate the difference between Schema Model & Target
Write-Output "Calculating differences between Schema Model and Target..."
$null = $targetConnectionString | flyway-dev @diffParams

# Step 2: Choose valid differences to process (default: all) and apply to the target
Write-Output "Taking valid differences to process..."
$changes = $targetConnectionString | flyway-dev take --project "$flywayProjectSettings" --artifact $diffArtifactFilePath --i-agree-to-the-eula

# Check for pending changes
if (-not $changes) {
    Write-Output 'Flyway: No Changes Found. Terminating Process'
    break
}

# Create dry-run script
$dryRunScriptPath = Join-Path $tempFilePath "FlywayDev_StateBasedDeploy_$((Get-Date).ToString('yyyyMMdd')).sql"
Write-Output "Applying changes and generating dry-run script..."
$null = $targetConnectionString | flyway-dev apply --project "$flywayProjectSettings" --artifact $diffArtifactFilePath --changes $changes --dry-run-script $dryRunScriptPath --i-agree-to-the-eula

Write-Output "The Dry Run Script can be found here: $dryRunScriptPath"

# Prompt for deployment
$continue = Read-Host "Review Deployment Script above. Deploy script? (y/n)"
if ($continue -notlike "y") {
    Write-Output 'Response not like "y". Target has NOT been updated.'
    break
}

# Step 3: Deploy to Target
Write-Output "Deploying to target..."
$null = $targetConnectionString | flyway-dev apply --project "$flywayProjectSettings" --artifact $diffArtifactFilePath --changes $changes --i-agree-to-the-eula

# Clean-up: Remove temp artifact files
try {
    Remove-Item $diffArtifactFilePath -Force
    Write-Output "Temporary artifact files cleaned up."
} catch {
    Write-Error "Failed to remove temporary artifact files: $_"
}