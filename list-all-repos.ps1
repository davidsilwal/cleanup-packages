# List all GitHub repositories for a user
# Usage: .\list-all-repos.ps1
# Token can be provided via -Token parameter or GITHUB_TOKEN in .env file

param(
    [string]$Token = "",
    [string]$Username = "",
    [switch]$PrivateOnly,  # Show only private repos
    [switch]$PublicOnly,   # Show only public repos
    [switch]$Detailed      # Show detailed information
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

# Set up headers for API request
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
}

if ($Token) {
    $headers["Authorization"] = "token $Token"
}

Write-Host "Fetching repositories for user: $Username" -ForegroundColor Cyan
Write-Host ""

# Fetch all repositories
$page = 1
$allRepos = @()

do {
    $url = "https://api.github.com/users/$Username/repos?per_page=100&page=$page&sort=updated&direction=desc"
    try {
        $repos = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $allRepos += $repos
        $page++
    } catch {
        Write-Host "Error fetching repositories: $_" -ForegroundColor Red
        exit 1
    }
} while ($repos.Count -eq 100)

# Filter based on visibility
if ($PrivateOnly) {
    $allRepos = $allRepos | Where-Object { $_.private -eq $true }
} elseif ($PublicOnly) {
    $allRepos = $allRepos | Where-Object { $_.private -eq $false }
}

$privateCount = ($allRepos | Where-Object { $_.private -eq $true }).Count
$publicCount = ($allRepos | Where-Object { $_.private -eq $false }).Count

Write-Host "Total repositories: $($allRepos.Count) (Private: $privateCount, Public: $publicCount)" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host ""

if ($Detailed) {
    # Detailed view
    foreach ($repo in $allRepos) {
        $visibility = if ($repo.private) { "Private" } else { "Public" }
        $visibilityColor = if ($repo.private) { "Yellow" } else { "Green" }
        
        Write-Host "Repository: " -NoNewline
        Write-Host $repo.name -ForegroundColor Cyan
        Write-Host "  Visibility: " -NoNewline
        Write-Host $visibility -ForegroundColor $visibilityColor
        Write-Host "  URL: $($repo.html_url)" -ForegroundColor Gray
        Write-Host "  Description: $($repo.description)" -ForegroundColor Gray
        Write-Host "  Updated: $($repo.updated_at)" -ForegroundColor Gray
        Write-Host "  Size: $($repo.size) KB" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    # Simple list view
    $counter = 1
    foreach ($repo in $allRepos) {
        $visibility = if ($repo.private) { "[Private]" } else { "[Public]" }
        $visibilityColor = if ($repo.private) { "Yellow" } else { "Green" }
        
        Write-Host ("{0,3}. " -f $counter) -NoNewline -ForegroundColor Gray
        Write-Host $repo.name -NoNewline -ForegroundColor Cyan
        Write-Host " " -NoNewline
        Write-Host $visibility -ForegroundColor $visibilityColor
        $counter++
    }
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "Total: $($allRepos.Count) repositories" -ForegroundColor Green

# Export to file option
Write-Host ""
Write-Host "Tip: To save to a text file, run:" -ForegroundColor Yellow
Write-Host "  .\list-all-repos.ps1 -Token `"your_token`" | Out-File repos-list.txt" -ForegroundColor Gray
