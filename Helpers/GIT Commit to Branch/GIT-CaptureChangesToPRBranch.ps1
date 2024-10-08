$flywayProjectPath = ($null -ne ${env:WORKING_DIRECTORY}) ? ${env:WORKING_DIRECTORY} : ${env:SYSTEM_DEFAULTWORKINGDIRECTORY}
Write-Host $(($null -ne ${env:WORKING_DIRECTORY}) ? "Environment Variable Used for 'Flyway Project Path'" : "Local Script Value Used for 'Flyway Project Path'")

Set-Location "$(WORKING_DIRECTORY)"

# Fetch source and target branches from the pull request variables
$branchSource = "${env:SYSTEM_PULLREQUEST_SOURCEBRANCH}"
$branchSourcePath = $branchSource -replace "refs/heads/", ""

$branchTarget = "${env:SYSTEM_PULLREQUEST_TARGETBRANCH}"
$branchTargetPath = $branchTarget -replace "refs/heads/", ""

# Ensure both source and target branches are available
if (-not $branchSourcePath) {
Write-Error "Source branch not found. Ensure System.PullRequest.SourceBranch is set."
exit 1
}

if (-not $branchTargetPath) {
Write-Error "Target branch not found. Ensure System.PullRequest.TargetBranch is set."
exit 1
}

Write-Host "Source branch: $branchSourcePath"
Write-Host "Target branch: $branchTargetPath"

# Add Git config items
Write-Host "Adding Git configuration for the Azure DevOps Build Agent..."
git config user.email "hosted.agent@dev.azure.com"
git config user.name "Azure Pipeline"
git config --global --add safe.directory '*'

# Step 1: Fetch and pull the latest information from the remote repository
Write-Host "Fetching and pulling latest changes from the remote repository..."
git fetch origin 
git branch --set-upstream-to=origin/$branchSourcePath $branchSourcePath
git pull --rebase origin $branchSourcePath
if ($LASTEXITCODE -ne 0) {
Write-Host "Git - Failed to Pull and Rebase from $branchSourcePath"
Write-Host "Git - Attempting to abort rebase"
git rebase --abort
Write-Host "Git - Retrying Rebase"
git pull --rebase origin $branchSourcePath
}

# Step 2: Stash any uncommitted changes
Write-Host "Stashing new .sql changes in the working repository..."
git add *.sql 
git stash 
if ($LASTEXITCODE -ne 0) {
Write-Error "Failed to stash changes. Exiting."
# Step 6a: Clean up pending commits if the push fails
git reset --hard HEAD~1
exit 1
}

# Step 3: Checkout source branch and merge the target branch into it
Write-Host "Checking out the source branch: $branchSourcePath"
git checkout $branchSourcePath
if ($LASTEXITCODE -ne 0) {
Write-Error "Failed to checkout source branch: $branchSourcePath. Exiting."
# Step 6a: Clean up pending commits if the push fails
git reset --hard HEAD~1
exit 1
}

# Step 4: Reapply stashed changes
Write-Host "Reapplying stashed changes..."
git stash pop
if ($LASTEXITCODE -ne 0) {
Write-Host "No Stashed Changes Found. Exiting Gracefully."
# Step 6a: Clean up pending commits if the push fails
git reset --hard HEAD~1
exit 0
}

git status

# Step 5: Stage and commit the changes
Write-Host "Committing changes..."
git add *.sql 
git commit -m "Flyway Dev - Auto Generated Migration Scripts. Solution source updated by ${env:BUILD_BUILDNUMBER} [skip ci] [skip pipeline]"
if ($LASTEXITCODE -ne 0) {
Write-Error "Failed to commit changes. Exiting."
# Step 6a: Clean up pending commits if the push fails
git reset --hard HEAD~1
exit 1
}

git status

# Step 6: Push the changes to the repository
Write-Host "Pushing changes to $branchSourcePath..."
git pull --rebase origin $branchSourcePath
git push origin $branchSourcePath
if ($LASTEXITCODE -ne 0) {
# Step 6a: If push fails (e.g., permission issues), clean up the pending commits
Write-Host "Push failed. Cleaning up local changes..."

# Reset the branch to its previous state to remove the pending commit
git reset --hard HEAD~1

Write-Host "Git Branch Reset"
exit 1
}

Write-Host "Changes successfully pushed to $branch."