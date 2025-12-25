# Delete GitHub packages (not just versions, but the entire package)
# Usage: .\delete-packages.ps1
# REQUIRES: Personal Access Token with 'delete:packages' and 'read:packages' scopes
# Token can be provided via -Token parameter or GITHUB_TOKEN in .env file

param(
    [string]$Token = "",
    [string]$Username = "",
    [string]$PackageType = "container",  # Options: npm, maven, rubygems, docker, nuget, container
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

# Load System.Web for URL encoding
Add-Type -AssemblyName System.Web

$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $Token"
}

Write-Host "Fetching all packages for user: $Username" -ForegroundColor Cyan

try {
    # Get all packages
    $url = "https://api.github.com/users/$Username/packages?package_type=$PackageType"
    $packages = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    
    if ($packages.Count -eq 0) {
        Write-Host "No packages found." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Found $($packages.Count) packages" -ForegroundColor Green
    
    foreach ($package in $packages) {
        $packageName = $package.name
        $encodedPackageName = [System.Web.HttpUtility]::UrlEncode($packageName)
        
        if ($WhatIf) {
            Write-Host "[WHATIF] Would delete package: $packageName" -ForegroundColor Magenta
        } else {
            Write-Host "Deleting package: $packageName" -ForegroundColor Red
            try {
                $deleteUrl = "https://api.github.com/users/$Username/packages/$PackageType/$encodedPackageName"
                Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete | Out-Null
                Write-Host "  ✓ Deleted" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Error: $_" -ForegroundColor Red
            }
        }
    }
    
    if ($WhatIf) {
        Write-Host "`n[WHATIF] Preview complete. Run without -WhatIf to actually delete packages." -ForegroundColor Yellow
    } else {
        Write-Host "`nAll packages deleted successfully!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Make sure your token has 'read:packages' and 'delete:packages' scopes." -ForegroundColor Yellow
    exit 1
}
