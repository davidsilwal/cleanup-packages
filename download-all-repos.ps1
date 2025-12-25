# Download all GitHub repositories for a user
# Usage: .\download-all-repos.ps1
# Token can be provided via -Token parameter or GITHUB_TOKEN in .env file

param(
    [string]$Token = "",
    [string]$Username = "",
    [string]$TargetDir = ".\repos"
)

# Function to load .env file
function Get-EnvVariable {
    param([string]$Key)
    
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*$Key\s*=\s*(.+)$") {
                return $matches[1].Trim()
            }
        }
    }
    return $null
}

# Load from .env if not provided
if ([string]::IsNullOrEmpty($Token)) {
    $Token = Get-EnvVariable "GITHUB_TOKEN"
}

if ([string]::IsNullOrEmpty($Username)) {
    $Username = Get-EnvVariable "GITHUB_USERNAME"
    if ([string]::IsNullOrEmpty($Username)) {
        $Username = "davidsilwal"
    }
}

# Create target directory if it doesn't exist
if (!(Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

Write-Host "Fetching repositories for user: $Username" -ForegroundColor Cyan

# Set up headers for API request
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
}

if ($Token) {
    $headers["Authorization"] = "token $Token"
}

# Fetch all repositories
$page = 1
$allRepos = @()

do {
    $url = "https://api.github.com/users/$Username/repos?per_page=100&page=$page"
    try {
        $repos = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $allRepos += $repos
        $page++
    } catch {
        Write-Host "Error fetching repositories: $_" -ForegroundColor Red
        exit 1
    }
} while ($repos.Count -eq 100)

Write-Host "Found $($allRepos.Count) repositories" -ForegroundColor Green

# Clone each repository
foreach ($repo in $allRepos) {
    $repoName = $repo.name
    $cloneUrl = $repo.clone_url
    $repoPath = Join-Path $TargetDir $repoName
    
    if (Test-Path $repoPath) {
        Write-Host "Repository '$repoName' already exists, pulling latest changes..." -ForegroundColor Yellow
        Push-Location $repoPath
        git pull
        Pop-Location
    } else {
        Write-Host "Cloning '$repoName'..." -ForegroundColor Cyan
        git clone $cloneUrl $repoPath
    }
}

Write-Host "`nAll repositories downloaded to: $TargetDir" -ForegroundColor Green
