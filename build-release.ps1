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
Set-Location -LiteralPath $PSScriptRoot
. (Join-Path $PSScriptRoot 'scripts/release-package.ps1')
if ($SkipBuild -and ($BumpMajor -or $BumpMinor -or $BumpPatch)) {
    throw 'A version bump requires a fresh build.'
}

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
$PackageVersion = if ($DryRun -and ($BumpMajor -or $BumpMinor -or $BumpPatch)) { "$Version+1" }
    else { Get-ReleaseVersion $PSScriptRoot }
$ReleaseName = "$AppName-v$PackageVersion-windows"
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

$BuildSource = $null
if (-not $SkipBuild) {
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw 'Flutter clean failed.' }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
    $BuildSource = @(Get-ReleaseSourceManifest $PSScriptRoot)
    flutter build windows --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows build failed.' }
}
$FlutterExecutable = if (-not $SkipBuild) { 'flutter' }
$release = New-WindowsReleasePackage -ProjectRoot $PSScriptRoot -AppName $AppName -ExeName $ExeName `
    -BuildSource $BuildSource -FlutterExecutable $FlutterExecutable -WriteChecksum -PreparePackage {
    param($OutputPath, $SourcePath)
    # Copy DEMO_DATA folder (sample CV and cover letter templates)
    Write-Host "  Copying demo data..." -ForegroundColor Gray
    if (Test-Path -LiteralPath (Join-Path $SourcePath 'DEMO_DATA')) {
        Copy-Item -LiteralPath (Join-Path $SourcePath 'DEMO_DATA') -Destination $OutputPath -Recurse
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
}

if ($AutoTag) { New-GitTag -Version $Version | Out-Null }
Write-Host "Created $($release.ZipPath) with $($release.SourceFiles) source files." -ForegroundColor Green
Write-Host "Test folder: $($release.OutputPath)"
