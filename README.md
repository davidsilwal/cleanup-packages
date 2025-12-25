# GitHub Cleanup Scripts

A collection of PowerShell scripts to manage and clean up GitHub repositories and packages.

## 📋 Prerequisites

- PowerShell 5.1 or later
- Git (for `download-all-repos.ps1`)
- GitHub Personal Access Token with appropriate scopes

## 🔑 Setup

### 1. Create GitHub Personal Access Token

Go to [GitHub Settings → Personal Access Tokens](https://github.com/settings/tokens/new) and create a token with these scopes:

- `delete_repo` - To delete repositories
- `read:packages` - To read packages
- `delete:packages` - To delete packages
- `repo` - To access private repositories (optional, for downloading private repos)

### 2. Configure Environment Variables

```powershell
# Copy the example file
Copy-Item .env.example .env

# Edit .env and add your token
notepad .env
```

**`.env` file format:**
```env
GITHUB_TOKEN=your_token_here
GITHUB_USERNAME=davidsilwal
```

**⚠️ IMPORTANT:** The `.env` file is in `.gitignore` to prevent accidentally committing your token.

## 📜 Available Scripts

### 1. List All Repositories

Display all your GitHub repositories.

```powershell
# Simple list
.\list-all-repos.ps1

# Detailed information
.\list-all-repos.ps1 -Detailed

# Show only private repos
.\list-all-repos.ps1 -PrivateOnly

# Show only public repos
.\list-all-repos.ps1 -PublicOnly

# Save to file
.\list-all-repos.ps1 > repos-list.txt
```

**Options:**
- `-Token` - Override token from .env
- `-Username` - Override username from .env
- `-Detailed` - Show detailed repo information
- `-PrivateOnly` - Show only private repositories
- `-PublicOnly` - Show only public repositories

---

### 2. Download All Repositories

Clone or update all your GitHub repositories locally.

```powershell
# Download to default ./repos directory
.\download-all-repos.ps1

# Download to specific directory
.\download-all-repos.ps1 -TargetDir "D:\MyRepos"
```

**Options:**
- `-Token` - Override token from .env
- `-Username` - Override username from .env
- `-TargetDir` - Target directory (default: `.\repos`)

**Note:** If repository already exists, it will pull latest changes instead of re-cloning.

---

### 3. Delete Package Versions

Delete old versions of GitHub packages, keeping only the most recent.

```powershell
# Preview what will be deleted
.\delete-all-packages.ps1 -WhatIf

# Delete all old versions (keep 2 most recent)
.\delete-all-packages.ps1
```

**Options:**
- `-Token` - Override token from .env
- `-Username` - Override username from .env
- `-PackageType` - Type of packages (default: `container`)
  - Options: `npm`, `maven`, `rubygems`, `docker`, `nuget`, `container`
- `-WhatIf` - Preview mode (safe, shows what would be deleted)

---

### 4. Delete Entire Packages

Delete entire packages (not just versions).

```powershell
# Preview what will be deleted
.\delete-packages.ps1 -WhatIf

# Delete all packages
.\delete-packages.ps1
```

**Options:**
- `-Token` - Override token from .env
- `-Username` - Override username from .env
- `-PackageType` - Type of packages (default: `container`)
- `-WhatIf` - Preview mode

**⚠️ WARNING:** This deletes the entire package, not just old versions!

---

### 5. Delete Repositories from List

Delete specific repositories listed in a text file.

```powershell
# 1. Edit the list of repos to delete
notepad repos-to-delete.txt

# 2. Preview what will be deleted (RECOMMENDED)
.\delete-repos-from-list.ps1 -RepoListFile "repos-to-delete.txt" -WhatIf

# 3. Actually delete the repositories
.\delete-repos-from-list.ps1 -RepoListFile "repos-to-delete.txt"
```

**Options:**
- `-Token` - Override token from .env
- `-Username` - Override username from .env
- `-RepoListFile` - Path to text file with repo names (required)
- `-WhatIf` - Preview mode

**Text file format (`repos-to-delete.txt`):**
```
# Lines starting with # are comments
# Empty lines are ignored

my-old-repo
test-project
deprecated-app
```

**⚠️ CRITICAL WARNING:** Deleting repositories is irreversible! Always use `-WhatIf` first!

---

## 🤖 GitHub Actions Workflow

The repository includes a GitHub Actions workflow that automatically cleans up old package versions.

**File:** `.github/workflows/cleanup-packages.yml`

**Schedule:** Runs every 3 days at midnight UTC

**Configuration:**
1. Add `PAT_TOKEN` secret to your repository:
   - Go to Repository Settings → Secrets and variables → Actions
   - Add new secret named `PAT_TOKEN`
   - Paste your Personal Access Token

**Manual trigger:**
- Go to Actions tab → "Daily Organization Package Cleanup" → Run workflow

---

## 🛡️ Safety Tips

1. **Always use `-WhatIf` first** before running destructive operations
2. **Backup important repositories** before deleting
3. **Double-check the list** in `repos-to-delete.txt` before running
4. **Never commit `.env`** file - it's in `.gitignore` for security
5. **Keep your token secure** - treat it like a password

## 📝 Examples

### Clean up everything
```powershell
# 1. List all repos
.\list-all-repos.ps1 > all-repos.txt

# 2. Delete old package versions
.\delete-all-packages.ps1 -WhatIf
.\delete-all-packages.ps1

# 3. Delete specific repos
notepad repos-to-delete.txt  # Edit the list
.\delete-repos-from-list.ps1 -RepoListFile "repos-to-delete.txt" -WhatIf
.\delete-repos-from-list.ps1 -RepoListFile "repos-to-delete.txt"
```

### Download all repos for backup
```powershell
.\download-all-repos.ps1 -TargetDir "D:\Backup\GitHub"
```

## 🆘 Troubleshooting

**Error: "GITHUB_TOKEN is required"**
- Make sure `.env` file exists and contains `GITHUB_TOKEN=your_token`
- Or pass token via `-Token` parameter

**Error: "Invalid argument" or "Not Found"**
- Check if your token has required scopes
- Verify the token hasn't expired

**Error: Package names with slashes fail**
- The scripts automatically URL-encode package names
- If issues persist, try manually specifying the package name

## 📄 License

MIT License - Feel free to use and modify these scripts.

## ⚠️ Disclaimer

These scripts perform destructive operations. Use at your own risk. Always test with `-WhatIf` first and ensure you have backups of important data.
