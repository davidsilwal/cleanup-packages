# Delete specific GitHub repositories listed in a text file
# Usage: .\delete-repos-from-list.ps1 -RepoListFile "repos.txt"
# REQUIRES: Personal Access Token with 'delete_repo' scope
# Token can be provided via -Token parameter or GITHUB_TOKEN in .env file

param(
    [string]$Token = "",
    [Parameter(Mandatory=$true)]
    [string]$RepoListFile,
    [string]$Username = "",
    [switch]$WhatIf  # Preview mode - shows what would be deleted without actually deleting
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

if ([string]::IsNullOrEmpty($Token)) {
    Write-Host "Error: GITHUB_TOKEN is required. Provide it via -Token parameter or create a .env file." -ForegroundColor Red
    Write-Host "See .env.example for format." -ForegroundColor Yellow
    exit 1
}

if (!(Test-Path $RepoListFile)) {
    Write-Host "Error: File '$RepoListFile' not found." -ForegroundColor Red
    exit 1
}

$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $Token"
}

# Read repository names from file (one per line, ignore empty lines and comments)
$repoNames = Get-Content $RepoListFile | Where-Object { 
    $_.Trim() -ne "" -and !$_.StartsWith("#") 
}

if ($repoNames.Count -eq 0) {
    Write-Host "No repository names found in '$RepoListFile'" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($repoNames.Count) repositories to delete from '$RepoListFile'" -ForegroundColor Cyan
Write-Host ""

foreach ($repoName in $repoNames) {
    $repoName = $repoName.Trim()
    
    if ($WhatIf) {
        Write-Host "[WHATIF] Would delete repository: $Username/$repoName" -ForegroundColor Magenta
    } else {
        Write-Host "Deleting repository: $Username/$repoName" -ForegroundColor Red
        try {
            $deleteUrl = "https://api.github.com/repos/$Username/$repoName"
            
            # First, verify the repo exists
            try {
                $repoInfo = Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Get
                Write-Host "  Repository found: $($repoInfo.full_name) (Private: $($repoInfo.private))" -ForegroundColor Gray
            } catch {
                Write-Host "  ✗ Repository not found or no access: $Username/$repoName" -ForegroundColor Yellow
                continue
            }
            
            # Delete the repository
            Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete | Out-Null
            Write-Host "  ✓ Deleted successfully" -ForegroundColor Green
            
        } catch {
            $errorMessage = $_.Exception.Message
            if ($_.ErrorDetails.Message) {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorMessage = $errorDetails.message
            }
            Write-Host "  ✗ Error: $errorMessage" -ForegroundColor Red
        }
    }
}

Write-Host ""
if ($WhatIf) {
    Write-Host "[WHATIF] Preview complete. Run without -WhatIf to actually delete repositories." -ForegroundColor Yellow
    Write-Host "WARNING: This action is irreversible! Make sure you have backups." -ForegroundColor Yellow
} else {
    Write-Host "Deletion process completed!" -ForegroundColor Green
}
