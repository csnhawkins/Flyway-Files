### Flyway CLI - Desktop Automation - Capture changes from Development database to Schema Model and individually generate a migration script for each change

# Flyway Project Settings - Specify the paths to the Flyway Project and Configuration files.

# These settings can either be configured directly in the script, or passed at runtime. For example, from a pipeline tool.

Write-Output "Using Local Variables for Flyway Project Settings"
# Local Variables - If Env Variables Not Set
$flywayProjectPath = "C:\WorkingFolders\FWD\NewWorldDB" # Ensure flyway.toml is explicitly referenced in filepath
$flywayProjectSettings = Join-Path $flywayProjectPath "flyway.toml"
$flywayProjectSchemaModel = Join-Path $flywayProjectPath "schema-model"
$flywayProjectMigrations = Join-Path $flywayProjectPath "migrations"
$flywayVersionDescription = "FlywayCLIAutomatedScript" # This will be the description for the Auto-Generated migration script
# Optional - Environment Details
$flywaySourceEnvironment = "development" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
$flywaySourceUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
$flywaySourcePassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
$flywayTargetEnvironment = "schemaModel" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
$flywayTargetUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
$flywayTargetPassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
$flywayBuildEnvironment = "shadow" # Options can be schemaModel, migrations, snapshot, empty, <<environment name>>
$flywayBuildUsername = "" # Optional - Can be used to specify database UserName is WindowsAuth or similar not utilized for the environment
$flywayBuildPassword = "" # Optional - Can be used to specify database password is WindowsAuth or similar not utilized for the environment
$pauseForInput = "true" # Set to true for interactive testing

$tempArtifactFolder = Join-Path $env:LOCALAPPDATA "Temp\Redgate\Flyway Desktop\Artifacts\$([guid]::NewGuid().ToString())" 
$diffArtifactFileName = "Flyway.$flywaySourceEnvironment.differences-$(get-date -f yyyyMMdd).diff"
if (-not (Test-Path $tempArtifactFolder)) {
  New-Item -ItemType Directory -Force -Path $tempArtifactFolder | Out-Null
}
$diffArtifactFilePath = Join-Path $tempArtifactFolder $diffArtifactFileName

# Apply the dev database to schema-model

# Flyway CLI - Shared Parameters List #
$commonParams =
@("-configFiles=$flywayProjectSettings",
"-schemaModelLocation=$flywayProjectSchemaModel",
"-locations=filesystem:$flywayProjectMigrations"
)

# Flyway CLI - Verb Parameters List #

# Step 1 - The Diff parameters define which source database or folder is compared against another. By default this is a Schema Model folder against a migrations folder (Represented using the Shadow Database)
$diffParams = @("diff", "-diff.source=$flywaySourceEnvironment" , "-diff.target=$flywayTargetEnvironment" ,"-diff.buildEnvironment=$flywayBuildEnvironment" ,"-environments.$flywayBuildEnvironment.user=$flywayBuildUsername" ,"-environments.$flywayBuildEnvironment.password=$flywayBuildPassword" ,"-environments.$flywayTargetEnvironment.user=$flywayTargetUsername" ,"-environments.$flywayTargetEnvironment.password=$flywayTargetPassword" ,"-diff.artifactFilename=$diffArtifactFilePath" ,"-outputType=json") + $commonParams

# Step 3 - All differences are then generated into a migration script
$generateParams = @("generate", "-generate.description=$flywayVersionDescription" ,"-generate.location=$flywayProjectMigrations" ,"-generate.types=versioned,undo" ,"-generate.artifactFilename=$diffArtifactFilePath" ,"-generate.addTimestamp=true") + $commonParams

# Capture differences between Development environment and Schema Model
Write-Host "Flyway CLI - Detecting differences between $flywaySourceEnvironment & $flywayTargetEnvironment"

flyway @diffParams | Tee-Object -Variable diffList

Write-Output "Creating list of changes"

# Parse JSON from diff output
$parsedDiff = $diffList -join "`n" | ConvertFrom-Json

# Create array of custom objects with ID and Object Name
$changes = $parsedDiff.differences | ForEach-Object {
    [PSCustomObject]@{
        Id         = $_.id
        Name       = $_.from.name
        Schema     = $_.from.schema
        ObjectType = $_.objectType
    }
}

Write-Output "Change IDs Found - $changeIds"

# Check if the previous command was successful
if ($? -eq $false) {
  Write-Error "Flyway CLI - Diff Command Failed. Exiting Session"
  exit 2  # Custom exit code to indicate a failure in the difference check command
}

# Check for "No differences found" in the result
if ($diffList -match "No differences found") {
  Write-Output "Flyway CLI - No Differences Found. Script Completed."
  
  # Clean-up: Remove temp artifact files
  try {
      Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
      Write-Output "Temporary artifact files cleaned up."
  } catch {
      Write-Error "Failed to remove temporary artifact files: $_"
  }
  # Conditionally pause console until user input provided
  if ($pauseForInput) {
    Read-Host "Press any key to exit"
    exit 0 # Success Exit Code
  }  
} else {
  Write-Output "Flyway CLI - Differences Found: Continuing to apply differences"
  Write-Output "Artifact File - $diffArtifactFilePath"
  flyway model "-model.artifactFilename=$diffArtifactFilePath"
}

Write-Output "Flyway CLI - Creating new migration script"
# Apply differences from Schema Model to Migration Folder

# Generate a separate script for each change
foreach ($change in $changes) {
    $safeName = $change.Name -replace '[^a-zA-Z0-9_]', '_' # sanitize filename
    $description = "$($change.ObjectType)_$($change.Schema)_$safeName"

    Write-Output "Generating migration for: $description (ID: $($change.Id))"

    $individualGenerateParams = @(
        "generate",
        "-generate.description=$description",
        "-generate.location=$flywayProjectMigrations",
        "-generate.types=versioned,undo",
        "-generate.artifactFilename=$diffArtifactFilePath",
        "-generate.changes=$($change.Id)",
        "-generate.addTimestamp=true"
    ) + $commonParams

    flyway @individualGenerateParams
}
# Clean-up: Remove temp artifact files
try {
  Remove-Item $tempArtifactFolder -Recurse -Force -Confirm:$false
  Write-Output "Temporary artifact files cleaned up."
  # Conditionally pause console until user input provided
  if ($pauseForInput) {
    Read-Host "Press any key to exit"
    exit 0 # Success Exit Code
  }  
} catch {
  Write-Error "Failed to remove temporary artifact files: $_"
}