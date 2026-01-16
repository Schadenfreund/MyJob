# Windows Release Build Script Template
# ==========================================
# This script automates the release build process for Flutter Windows apps.
#
# Features:
# - Auto-reads version from pubspec.yaml
# - Optional version auto-increment (Major, Minor, Patch)
# - Cleans and builds release
# - Creates portable package with UserData structure
# - Generates ZIP archive ready for GitHub Release
# - Creates SHA256 checksum file
# - Validates CHANGELOG.md has entry for version
# - Optional automatic git tagging
#
# Usage:
#   .\build-release.ps1                    # Build with current version
#   .\build-release.ps1 -BumpPatch         # Increment patch (1.0.0 -> 1.0.1)
#   .\build-release.ps1 -BumpMinor         # Increment minor (1.0.0 -> 1.1.0)
#   .\build-release.ps1 -BumpMajor         # Increment major (1.0.0 -> 2.0.0)
#   .\build-release.ps1 -BumpPatch -AutoTag  # Bump and create git tag
#   .\build-release.ps1 -BumpPatch -DryRun   # Preview changes without executing
#
# Prerequisites:
#   - Flutter SDK in PATH
#   - PowerShell 5.0+
#   - Git (for tagging)

param(
    [switch]$BumpMajor,
    [switch]$BumpMinor,
    [switch]$BumpPatch,
    [switch]$AutoTag,
    [switch]$DryRun,
    [switch]$SkipBuild,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# ============== HELP ==============
if ($Help) {
    Write-Host @"

MyJob Release Build Script
==========================

USAGE:
    .\build-release.ps1 [OPTIONS]

OPTIONS:
    -BumpMajor    Increment major version (1.0.0 -> 2.0.0)
    -BumpMinor    Increment minor version (1.0.0 -> 1.1.0)
    -BumpPatch    Increment patch version (1.0.0 -> 1.0.1)
    -AutoTag      Create and push git tag after successful build
    -DryRun       Preview all changes without executing them
    -SkipBuild    Skip Flutter build (use existing build)
    -Help         Show this help message

EXAMPLES:
    .\build-release.ps1                     # Build with current version
    .\build-release.ps1 -BumpPatch          # Bump patch and build
    .\build-release.ps1 -BumpMinor -AutoTag # Bump minor, build, and tag
    .\build-release.ps1 -BumpPatch -DryRun  # Preview patch bump

"@
    exit 0
}

# ============== CONFIGURATION ==============
$AppName = "MyJob"
$ExeName = "$AppName.exe"
$PubspecPath = "pubspec.yaml"
$ConstantsPath = "lib\constants\app_constants.dart"
$ChangelogPath = "CHANGELOG.md"

# ============== FUNCTIONS ==============

function Get-CurrentVersion {
    $content = Get-Content $PubspecPath -Raw
    if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)') {
        return @{
            Major = [int]$matches[1]
            Minor = [int]$matches[2]
            Patch = [int]$matches[3]
            String = "$($matches[1]).$($matches[2]).$($matches[3])"
        }
    }
    throw "Could not parse version from pubspec.yaml"
}

function Get-IncrementedVersion {
    param(
        [hashtable]$Current,
        [switch]$Major,
        [switch]$Minor,
        [switch]$Patch
    )

    $newMajor = $Current.Major
    $newMinor = $Current.Minor
    $newPatch = $Current.Patch

    if ($Major) {
        $newMajor++
        $newMinor = 0
        $newPatch = 0
    }
    elseif ($Minor) {
        $newMinor++
        $newPatch = 0
    }
    elseif ($Patch) {
        $newPatch++
    }

    return @{
        Major = $newMajor
        Minor = $newMinor
        Patch = $newPatch
        String = "$newMajor.$newMinor.$newPatch"
    }
}

function Update-PubspecVersion {
    param([string]$NewVersion)

    $content = Get-Content $PubspecPath -Raw
    # Update version line (preserving build number format)
    $content = $content -replace 'version:\s*\d+\.\d+\.\d+(\+\d+)?', "version: $NewVersion+1"

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would update pubspec.yaml version to: $NewVersion+1" -ForegroundColor Cyan
    } else {
        Set-Content $PubspecPath $content -NoNewline
        Write-Host "  Updated pubspec.yaml to version $NewVersion+1" -ForegroundColor Green
    }
}

function Update-AppConstantsVersion {
    param([string]$NewVersion)

    if (-not (Test-Path $ConstantsPath)) {
        Write-Host "  Warning: $ConstantsPath not found, skipping" -ForegroundColor Yellow
        return
    }

    $content = Get-Content $ConstantsPath -Raw
    $content = $content -replace "static const String version = '\d+\.\d+\.\d+'", "static const String version = '$NewVersion'"

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would update app_constants.dart version to: $NewVersion" -ForegroundColor Cyan
    } else {
        Set-Content $ConstantsPath $content -NoNewline
        Write-Host "  Updated app_constants.dart to version $NewVersion" -ForegroundColor Green
    }
}

function Test-ChangelogEntry {
    param([string]$Version)

    if (-not (Test-Path $ChangelogPath)) {
        Write-Host "  Warning: CHANGELOG.md not found" -ForegroundColor Yellow
        return $false
    }

    $content = Get-Content $ChangelogPath -Raw

    # Check for version entry like [1.0.1] or ## [1.0.1]
    if ($content -match "\[$Version\]") {
        Write-Host "  Changelog entry found for version $Version" -ForegroundColor Green
        return $true
    }

    Write-Host "  WARNING: No CHANGELOG.md entry found for version $Version" -ForegroundColor Yellow
    Write-Host "  Consider adding an entry before releasing." -ForegroundColor Yellow
    return $false
}

function New-GitTag {
    param([string]$Version)

    $tagName = "v$Version"

    # Check if tag already exists
    $existingTag = git tag -l $tagName 2>$null
    if ($existingTag) {
        Write-Host "  Warning: Tag $tagName already exists" -ForegroundColor Yellow
        return $false
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create git tag: $tagName" -ForegroundColor Cyan
        Write-Host "  [DRY RUN] Would push tag to origin" -ForegroundColor Cyan
    } else {
        Write-Host "  Creating git tag: $tagName" -ForegroundColor Yellow
        git tag -a $tagName -m "Release $tagName"

        Write-Host "  Pushing tag to origin..." -ForegroundColor Yellow
        git push origin $tagName

        Write-Host "  Git tag $tagName created and pushed" -ForegroundColor Green
    }
    return $true
}

function New-Checksum {
    param([string]$FilePath)

    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    $checksumFile = "$FilePath.sha256"
    $checksumContent = "$($hash.Hash.ToLower())  $(Split-Path $FilePath -Leaf)"

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create checksum: $checksumFile" -ForegroundColor Cyan
    } else {
        $checksumContent | Out-File $checksumFile -Encoding ASCII -NoNewline
        Write-Host "  Created checksum: $checksumFile" -ForegroundColor Green
    }

    return $checksumFile
}

# ============== MAIN SCRIPT ==============

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  $AppName Release Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "  *** DRY RUN MODE - No changes will be made ***" -ForegroundColor Magenta
    Write-Host ""
}

# Step 1: Get current version and calculate new version if bumping
$currentVersion = Get-CurrentVersion
Write-Host "[1/8] Version Management" -ForegroundColor Yellow
Write-Host "  Current version: $($currentVersion.String)" -ForegroundColor White

$targetVersion = $currentVersion

if ($BumpMajor -or $BumpMinor -or $BumpPatch) {
    $targetVersion = Get-IncrementedVersion -Current $currentVersion -Major:$BumpMajor -Minor:$BumpMinor -Patch:$BumpPatch
    Write-Host "  Target version:  $($targetVersion.String)" -ForegroundColor Green

    # Update version files
    Write-Host ""
    Write-Host "[2/8] Updating Version Files" -ForegroundColor Yellow
    Update-PubspecVersion -NewVersion $targetVersion.String
    Update-AppConstantsVersion -NewVersion $targetVersion.String
} else {
    Write-Host "  No version bump requested, using current version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2/8] Skipping Version Update" -ForegroundColor Gray
}

$Version = $targetVersion.String

# Step 3: Validate changelog
Write-Host ""
Write-Host "[3/8] Validating Changelog" -ForegroundColor Yellow
Test-ChangelogEntry -Version $Version | Out-Null

# Configuration
$ReleaseName = "$AppName-v$Version-windows"
$BuildPath = "build\windows\x64\runner\Release"
$OutputPath = "releases\$ReleaseName"

if ($DryRun) {
    Write-Host ""
    Write-Host "[4/8] [DRY RUN] Would clean previous builds" -ForegroundColor Cyan
    Write-Host "[5/8] [DRY RUN] Would run Flutter build" -ForegroundColor Cyan
    Write-Host "[6/8] [DRY RUN] Would create release package at: $OutputPath" -ForegroundColor Cyan
    Write-Host "[7/8] [DRY RUN] Would create ZIP: releases\$ReleaseName.zip" -ForegroundColor Cyan

    if ($AutoTag) {
        Write-Host "[8/8] [DRY RUN] Would create and push git tag v$Version" -ForegroundColor Cyan
    } else {
        Write-Host "[8/8] Skipping Git Tag (use -AutoTag to enable)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Dry Run Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Run without -DryRun to execute" -ForegroundColor White
    exit 0
}

# Step 4: Clean previous builds
Write-Host ""
Write-Host "[4/8] Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
}
if (Test-Path "releases\$ReleaseName") {
    Remove-Item -Recurse -Force "releases\$ReleaseName"
}

# Step 5: Build
if ($SkipBuild) {
    Write-Host ""
    Write-Host "[5/8] Skipping Flutter build (using existing)" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "[5/8] Building Windows release..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    flutter build windows --release

    if (-not (Test-Path "$BuildPath\$ExeName")) {
        Write-Host "Build failed! $ExeName not found." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Build successful!" -ForegroundColor Green
}

# Step 6: Create release package
Write-Host ""
Write-Host "[6/8] Creating release package..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

# Copy executable and DLLs
Write-Host "  Copying executable and DLLs..." -ForegroundColor Gray
Copy-Item "$BuildPath\$ExeName" $OutputPath
Get-ChildItem "$BuildPath\*.dll" | Copy-Item -Destination $OutputPath

# Copy data folder (flutter assets)
Write-Host "  Copying app resources..." -ForegroundColor Gray
Copy-Item "$BuildPath\data" $OutputPath -Recurse

# Copy documentation
Write-Host "  Copying documentation..." -ForegroundColor Gray
Copy-Item "README.md" $OutputPath -ErrorAction SilentlyContinue
Copy-Item "LICENSE" $OutputPath -ErrorAction SilentlyContinue
Copy-Item "CHANGELOG.md" $OutputPath -ErrorAction SilentlyContinue
Copy-Item "QUICK_START.md" $OutputPath -ErrorAction SilentlyContinue

# Copy DEMO_DATA folder (sample CV and cover letter templates)
Write-Host "  Copying demo data..." -ForegroundColor Gray
if (Test-Path "DEMO_DATA") {
    Copy-Item "DEMO_DATA" $OutputPath -Recurse
}

# Create UserData structure (for portable app)
Write-Host "  Creating UserData structure..." -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$OutputPath\UserData" | Out-Null

# Create UserData README
@"
# UserData Folder

This folder contains your personal settings and configurations.

## What's Stored Here:
- user_data.json - Your app configuration, profile and application data

## Important Notes:
- **This folder is preserved during updates!**
  When updating the app, your settings remain intact.

- **Portable Installation:**
  UserData is stored alongside the executable.

- **Backup Recommended:**
  Consider backing up this folder before major updates.
"@ | Out-File "$OutputPath\UserData\README.txt" -Encoding UTF8

Write-Host "  Release package created!" -ForegroundColor Green

# Step 7: Create ZIP archive and checksum
Write-Host ""
Write-Host "[7/8] Creating ZIP archive and checksum..." -ForegroundColor Yellow
$ZipPath = "releases\$ReleaseName.zip"
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath
}

Compress-Archive -Path $OutputPath -DestinationPath $ZipPath -CompressionLevel Optimal

# Get file size
$ZipSize = (Get-Item $ZipPath).Length / 1MB
Write-Host "  ZIP created: $ZipPath ($([math]::Round($ZipSize, 2)) MB)" -ForegroundColor Green

# Create SHA256 checksum
New-Checksum -FilePath $ZipPath | Out-Null

# Step 8: Git tagging
Write-Host ""
if ($AutoTag) {
    Write-Host "[8/8] Creating Git Tag..." -ForegroundColor Yellow
    New-GitTag -Version $Version | Out-Null
} else {
    Write-Host "[8/8] Skipping Git Tag (use -AutoTag to enable)" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release Package Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Version:      $Version" -ForegroundColor White
Write-Host "  Package:      $ZipPath" -ForegroundColor White
Write-Host "  Checksum:     $ZipPath.sha256" -ForegroundColor White
Write-Host "  Size:         $([math]::Round($ZipSize, 2)) MB" -ForegroundColor White
Write-Host "  Folder:       $OutputPath" -ForegroundColor White
Write-Host ""

# Package Contents
Write-Host "Package Contents:" -ForegroundColor Yellow
Get-ChildItem $OutputPath -Recurse -File | Select-Object -ExpandProperty FullName | ForEach-Object {
    $relativePath = $_.Substring((Get-Item $OutputPath).FullName.Length + 1)
    Write-Host "  - $relativePath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $AutoTag) {
    Write-Host "1. Create Git tag (or re-run with -AutoTag):" -ForegroundColor White
    Write-Host "   git tag -a v$Version -m `"Release v$Version`"" -ForegroundColor Gray
    Write-Host "   git push origin v$Version" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "2. Create GitHub Release at:" -ForegroundColor White
Write-Host "   https://github.com/Schadenfreund/MyJob/releases/new?tag=v$Version" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Upload these files to the release:" -ForegroundColor White
Write-Host "   - $ZipPath" -ForegroundColor Gray
Write-Host "   - $ZipPath.sha256" -ForegroundColor Gray
Write-Host ""
Write-Host "Release build complete!" -ForegroundColor Green
