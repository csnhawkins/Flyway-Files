$flywayProjectPath = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : ${env:SYSTEM_DEFAULTWORKINGDIRECTORY}
Write-Host $(($null -ne ${env:WORKING_DIRECTORY}) ? "Environment Variable Used for 'Flyway Project Path'" : "Local Script Value Used for 'Flyway Project Path'")

Set-Location "$(WORKING_DIRECTORY)"

# Configure Git
Write-Host "Updating Git Config to use Azure DevOps Build Agent details..."
git config user.email "hosted.agent@dev.azure.com"
git config user.name "Azure Pipeline"
git config --global --add safe.directory '*'

# Check if source branch is available
$branchSourcePath = ${env:BUILD_SOURCEBRANCH} -replace "refs/heads/",""
if (-not $branchSourcePath) {
    Write-Error "Source branch not found. Ensure the branch is correctly set in Build_SourceBranch."
    exit 1
}

Write-Host "Source branch: $branchSourcePath"

# Checkout the source branch and check its status
Write-Host "Checking out branch: $branchSourcePath"
git fetch -origin
git branch --set-upstream-to=origin/$branchSourcePath $branchSourcePath
git pull --rebase origin $branchSourcePath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git - Failed to Pull and Rebase from $branchSourcePath"
    Write-Host "Git - Attempting to abort rebase"
    git rebase --abort
    Write-Host "Git - Retrying Rebase"
    git pull --rebase origin $branchSourcePath
}
git checkout $branchSourcePath
if ($?) {
    git status
} else {
    Write-Error "Failed to checkout branch: $branchSourcePath"
    exit 1
}

# Create a temporary branch for the new changes
$tempBranchName = "Build/FlywayDev-${env:BUILD_BUILDNUMBER}-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Creating temporary branch: $tempBranchName"
git switch -c $tempBranchName
if (-not $?) {
    Write-Error "Failed to create a temporary branch."
    exit 1
}

# Stage and commit changes
Write-Host "Staging and committing all changes..."
git add --all
git commit -m "Flyway Dev - Auto Generated Migration Scripts. Solution source updated by ${env:BUILD_BUILDNUMBER} [skip ci] [skip pipeline]"
if (-not $?) {
    Write-Host "Git - No Changes Found. Exiting Gracefully"
    exit 0
}

# Fetch and merge changes back into the source branch
Write-Host "Fetching updates and merging changes into $branchSourcePath..."
git fetch --all
git checkout $branchSourcePath
git merge $tempBranchName -m "Merge from $tempBranchName into $branchSourcePath"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Merge failed. Resolve conflicts manually."
    exit 1
}

# Push changes back to the repository
Write-Host "Pushing changes to $branchSourcePath..."
git pull --rebase origin $branchSourcePath
git push origin $branchSourcePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed. Ensure repository permissions are correct."
    exit 1
}

Write-Host "Changes pushed successfully to $branchSourcePath"