# Build static OpenSSL for Windows x64 using MSVC with /MT (static runtime).
#
# Produces:
#   thirdparty/openssl-windows/x64/
#     include/openssl/    (headers)
#     lib/libssl.lib
#     lib/libcrypto.lib
#
# Requires:
#   - Visual Studio x64 developer environment (cl.exe, nmake.exe in PATH)
#   - Strawberry Perl (checked automatically; installed via choco if missing)
#   - NASM (checked automatically; installed via choco if missing)
#
# Usage (from repo root, in a VS x64 Dev Prompt or after ilammy/msvc-dev-cmd):
#   .\scripts\build_openssl_windows.ps1
#   .\scripts\build_openssl_windows.ps1 -OpenSslVersion 3.4.1 -Force

param(
    [string]$OpenSslVersion = "3.4.1",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $repoRoot "thirdparty\openssl-windows\x64"
$tarball = Join-Path $env:TEMP "openssl-$OpenSslVersion.tar.gz"
$srcDir = Join-Path $env:TEMP "openssl-$OpenSslVersion"
$buildDir = Join-Path $env:TEMP "openssl-windows-build"

# ── Early exit if already built ────────────────────────────────────────────
if ((Test-Path "$outDir\lib\libssl.lib") -and -not $Force) {
    Write-Host "Static OpenSSL already built at $outDir  (pass -Force to rebuild)"
    exit 0
}

# ── Verify / activate MSVC environment ────────────────────────────────────
# If cl.exe is missing OR INCLUDE is not set (env not activated), find vcvarsall and import it.
$needVsEnv = (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) -or ([string]::IsNullOrEmpty($env:INCLUDE))
if ($needVsEnv) {
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    }
    if (-not $vsPath) {
        # Fallback: common VS 2022 paths
        $vsPath = @(
            'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
            'C:\Program Files\Microsoft Visual Studio\2022\Professional',
            'C:\Program Files\Microsoft Visual Studio\2022\Community',
            'C:\Program Files\Microsoft Visual Studio\2022\BuildTools'
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    if (-not $vsPath) {
        throw "Visual Studio not found. Install VS 2022 with C++ workload, or run from a VS x64 Developer Command Prompt."
    }
    $vcvarsall = Join-Path $vsPath 'VC\Auxiliary\Build\vcvarsall.bat'
    if (-not (Test-Path $vcvarsall)) {
        throw "vcvarsall.bat not found at $vcvarsall"
    }
    Write-Host "Activating MSVC x64 environment from $vcvarsall ..."
    $envLines = cmd /c "`"$vcvarsall`" amd64 > nul 2>&1 && set"
    $envLines | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    throw "cl.exe not found after MSVC environment activation."
}
if (-not (Get-Command nmake.exe -ErrorAction SilentlyContinue)) {
    throw "nmake.exe not found after MSVC environment activation."
}

# ── Strawberry Perl ────────────────────────────────────────────────────────
# MSYS2/Git Perl must NOT be used for MSVC OpenSSL builds.
$strawberryPerl = "C:\Strawberry\perl\bin\perl.exe"
if (-not (Test-Path $strawberryPerl)) {
    Write-Host "Strawberry Perl not found. Installing via choco..."
    choco install strawberryperl -y --no-progress --limit-output
    if (-not (Test-Path $strawberryPerl)) {
        throw "Strawberry Perl installation failed."
    }
}
Write-Host "Using Strawberry Perl: $strawberryPerl"

# ── NASM (optional; not needed when using no-asm build) ───────────────────
if (-not (Get-Command nasm -ErrorAction SilentlyContinue)) {
    Write-Host "NASM not found. Proceeding with no-asm (C fallbacks for crypto ops)."
}

# ── Download ────────────────────────────────────────────────────────────────
if (-not (Test-Path $tarball)) {
    Write-Host "Downloading OpenSSL $OpenSslVersion ..."
    Invoke-WebRequest "https://www.openssl.org/source/openssl-$OpenSslVersion.tar.gz" `
        -OutFile $tarball -UseBasicParsing
}

if (-not (Test-Path $srcDir)) {
    Write-Host "Extracting ..."
    tar -xzf $tarball -C $env:TEMP
}

# ── Configure + build ───────────────────────────────────────────────────────
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
Copy-Item $srcDir $buildDir -Recurse -Force

Push-Location $buildDir
try {
    Write-Host ""
    Write-Host "Configuring OpenSSL $OpenSslVersion for VC-WIN64A (/MT, no-shared) ..."
    # -MT: static MSVC runtime (matches libtorrent's CMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded)
    # no-asm: skip NASM requirement; use C fallbacks (acceptable for functionality, minor perf cost)
    & $strawberryPerl Configure VC-WIN64A `
        no-shared `
        no-tests `
        no-asm `
        -MT `
        "--prefix=$outDir" `
        "--openssldir=$outDir\ssl"

    Write-Host ""
    Write-Host "Generating required headers ..."
    nmake build_generated

    Write-Host "Building libcrypto.lib and libssl.lib (this may take several minutes) ..."
    # Build only the two libs we need; avoid apps\libapps.lib which is also in LIBS
    nmake libcrypto.lib libssl.lib

    Write-Host "Installing headers and libs to $outDir ..."
    # Manually copy instead of 'nmake install_dev' to avoid the apps\libapps.lib dependency
    $null = New-Item -ItemType Directory -Force "$outDir\include\openssl"
    $null = New-Item -ItemType Directory -Force "$outDir\lib"
    # Source tree headers (public API)
    Copy-Item "$buildDir\include\openssl\*.h" "$outDir\include\openssl\" -Force
    Copy-Item "$srcDir\include\openssl\*.h"   "$outDir\include\openssl\" -Force
    # Built libs
    Copy-Item "$buildDir\libcrypto.lib" "$outDir\lib\" -Force
    Copy-Item "$buildDir\libssl.lib"    "$outDir\lib\" -Force
    # PDB for static lib (needed by MSVC linker)
    if (Test-Path "$buildDir\ossl_static.pdb") {
        Copy-Item "$buildDir\ossl_static.pdb" "$outDir\lib\" -Force
    }
}
finally {
    Pop-Location
}

# ── Verify output ────────────────────────────────────────────────────────────
foreach ($f in @("lib\libssl.lib", "lib\libcrypto.lib", "include\openssl\ssl.h")) {
    if (-not (Test-Path (Join-Path $outDir $f))) {
        throw "Expected output not found: $outDir\$f"
    }
}

$ssl = [math]::Round((Get-Item "$outDir\lib\libssl.lib").Length / 1MB, 1)
$cry = [math]::Round((Get-Item "$outDir\lib\libcrypto.lib").Length / 1MB, 1)
Write-Host ""
Write-Host "Done!  libssl.lib=${ssl}MB  libcrypto.lib=${cry}MB"
Write-Host "OPENSSL_ROOT_DIR => $outDir"
