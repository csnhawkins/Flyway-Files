
# Specify the paths to the Flyway Project and Configuration files

$flywayProjectPath = "C:\WorkingFolders\FWD\NewWorldDB" # Ensure flyway.toml is explicitly referenced in filepath
$flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"

# Apply the dev database to schema-model

# Define temporary diff file and path
$diffArtifactFileName = New-Guid 
$tempFilePath = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\comparison_artifacts_Dev_SchemaModel" 
$null = New-Item -ItemType Directory -Force -Path $tempFilePath
$diffArtifactFilePath = Join-Path $tempFilePath $diffArtifactFileName

# Parameters for Flyway dev
$commonParams =
@("--artifact=$diffArtifactFilePath",
"--project=$flywayProjectSettings",
"--i-agree-to-the-eula")

$diffParams = @("diff", "--from=Dev" ,"--to=SchemaModel") + $commonParams
$takeParams = @("take") + $commonParams
$applyParams = @("apply") + $commonParams

#Step 1: Calculate the difference between two targets
flyway-dev @diffParams
#Step 2: Choose valid differences to process (By default this will be all) and pass this to be applied to the schema model
flyway-dev @takeParams | flyway-dev @applyParams

# Clean-up: Remove temp artifact files
Remove-Item $diffArtifactFilePath