<#
.SYNOPSIS
    Cross-compile a static OpenSSL for Android arm64-v8a using the NDK.

.DESCRIPTION
    On Windows this script delegates to WSL (Windows Subsystem for Linux) which
    has a proper POSIX Perl and make.  The bash script at
    scripts/build_openssl_android.sh contains the actual build logic.

    On Linux / macOS the bash script is invoked directly.

    Produces:
        thirdparty/openssl-android/arm64-v8a/
            include/openssl/   (headers)
            lib/libssl.a
            lib/libcrypto.a

.PARAMETER OpenSslVersion
    OpenSSL tarball version to download (default: 3.4.1).

.PARAMETER NdkHome
    Path to the NDK root.  Defaults to $env:ANDROID_NDK_HOME.

.PARAMETER Force
    Rebuild even if the output already exists.
#>
param(
    [string]$OpenSslVersion = "3.4.1",
    [string]$NdkHome = $env:ANDROID_NDK_HOME,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = Resolve-Path "$PSScriptRoot\.."
$outDir = Join-Path $repo "thirdparty\openssl-android\arm64-v8a"
$shScript = Join-Path $repo "scripts\build_openssl_android.sh"

if ((Test-Path "$outDir\lib\libssl.a") -and -not $Force) {
    Write-Host "Static OpenSSL already built at $outDir  (use -Force to rebuild)"
    exit 0
}

if (-not $NdkHome) {
    Write-Error "ANDROID_NDK_HOME is not set.  Pass -NdkHome or set the environment variable."
}

# ── Delegate to the bash script via WSL ─────────────────────────────────────
# OpenSSL's Configure uses forward-slash regex to detect the NDK compiler.
# On Windows, Perl's canonpath() returns backslashes so the match always fails.
# WSL provides a real Linux Perl + make; it accesses the Windows filesystem at /mnt/c/...

$wsl = Get-Command wsl -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $wsl) {
    Write-Error @"
WSL (Windows Subsystem for Linux) is required to cross-compile OpenSSL on Windows.

Enable WSL and install a Linux distro:
  wsl --install

Then re-run this script.  Alternatively, run the GitHub Actions release workflow
on a Linux runner which builds OpenSSL natively.
"@
}

function ConvertTo-WslPath([string]$p) {
    if ($p -match '^([A-Za-z]):(.*)') {
        $drive = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive$rest"
    }
    return $p -replace '\\', '/'
}

$ndkWsl = ConvertTo-WslPath $NdkHome
$repoWsl = ConvertTo-WslPath $repo
$scriptWsl = ConvertTo-WslPath $shScript
$forceArg = if ($Force) { "--force" } else { "" }

Write-Host "Running OpenSSL cross-compile via WSL..."
Write-Host "  NDK:    $ndkWsl"
Write-Host "  Output: $repoWsl/thirdparty/openssl-android/arm64-v8a"

wsl bash -c "ANDROID_NDK_HOME='$ndkWsl' bash '$scriptWsl' '$OpenSslVersion' '$forceArg'"
if ($LASTEXITCODE -ne 0) { throw "OpenSSL build failed (see WSL output above)" }

Write-Host ""
Write-Host "Done!  OPENSSL_ROOT_DIR => $outDir"
