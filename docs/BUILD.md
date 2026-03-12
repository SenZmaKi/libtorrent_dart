# Building libtorrent_dart

This guide covers building the native bridge for all supported targets.

## Versioned binary layout (important)

At load time, the Dart hook (`hook/build.dart`) resolves the package version
from `pubspec.yaml` and loads binaries from:

```
binaries/<platform>/<package-version>/<binary-name>
```

Example for package version `0.3.2` on Linux:

```
binaries/linux/0.3.2/libtorrent-rasterbar.so
```

This prevents accidentally loading stale binaries from an older package version.
When building manually, pass `-DLTD_BINARY_LAYOUT_VERSION=<package-version>` so
the output path matches what the hook will load.

If the binary is not found locally, the hook automatically attempts to download
it from the matching GitHub release. This behaviour can be overridden with two
environment variables:

| Variable                 | Purpose                                                              |
| ------------------------ | -------------------------------------------------------------------- |
| `LTD_RELEASE_TAG`        | Override the release tag to download from (default: package version) |
| `LTD_RELEASE_REPOSITORY` | Override the GitHub repo (default: `SenZmaKi/libtorrent_dart`)       |

## Prerequisites (all platforms)

- CMake 3.20+
- Ninja (`brew install ninja` / `apt install ninja-build` / `choco install ninja`)
- ccache (`brew install ccache` / `apt install ccache` / `choco install ccache`)
- Boost headers 1.80+ (see per-platform instructions below)
- Dart SDK ≥ 3.7.0
- Git with submodules:

```sh
git clone --recursive https://github.com/SenZmaKi/libtorrent_dart.git
cd libtorrent_dart
```

## CMake Presets

The project ships a `CMakePresets.json` with ready-made presets. All build
output lands in `cmake_build/<preset-name>/` and binaries are written to
`binaries/<platform>/<version>/`.

| Preset    | Platform | Generator | Notes                                                 |
| --------- | -------- | --------- | ----------------------------------------------------- |
| `linux`   | Linux    | Ninja     | gcc/clang, ccache, Boost from `/usr/include`          |
| `macos`   | macOS    | Ninja     | clang, ccache, Boost from `/opt/homebrew/include`     |
| `windows` | Windows  | Ninja     | **MSVC only** (cl.exe), ccache, static MSVC runtime   |
| `android` | Android  | Ninja     | arm64-v8a, API 24, NDK toolchain, c++\_static, ccache |
| `ios`     | iOS      | Xcode     | arm64, deployment target 13.0, no OpenSSL             |

## Linux

```sh
sudo apt-get install -y cmake ninja-build ccache libboost-dev libssl-dev

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
cmake --preset linux -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset linux --parallel
```

Output: `binaries/linux/<version>/libtorrent-rasterbar.so`

## macOS

```sh
brew install cmake ninja ccache boost openssl@3

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
BOOST_INC="$(brew --prefix boost)/include"
OPENSSL_ROOT="$(brew --prefix openssl@3)"
cmake --preset macos \
  -DLTD_BOOST_HEADERS_ROOT="$BOOST_INC" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT" \
  -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset macos --parallel
```

Output: `binaries/macos/<version>/libtorrent-rasterbar.dylib`

## Windows (MSVC)

**Requirements:** Visual Studio 2022 with the C++ workload. Run all commands
from a **VS x64 Developer Command Prompt** (or after `ilammy/msvc-dev-cmd`).
MinGW / LLVM-MinGW are not supported.

```powershell
# Install Boost (places headers under C:\local\boost_*)
choco install boost-msvc-14.3 -y
choco install ccache -y

# Build static OpenSSL (output: thirdparty\openssl-windows\x64\)
.\scripts\build_openssl_windows.ps1

$boostDir = Get-ChildItem 'C:\local' -Directory | Where-Object { $_.Name -like 'boost_*' } | Select-Object -First 1
$version  = (Select-String pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$OPENSSL  = "$(Get-Location)\thirdparty\openssl-windows\x64"

cmake --preset windows `
  -DLTD_BOOST_HEADERS_ROOT="$($boostDir.FullName)" `
  -DLTD_BINARY_LAYOUT_VERSION="$version" `
  -DOPENSSL_ROOT_DIR="$OPENSSL" `
  -DOPENSSL_SSL_LIBRARY="$OPENSSL\lib\libssl.lib" `
  -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL\lib\libcrypto.lib" `
  -DOPENSSL_INCLUDE_DIR="$OPENSSL\include"
cmake --build --preset windows --parallel
```

`build_openssl_windows.ps1` downloads OpenSSL 3.4.1, installs Strawberry Perl
via choco if needed, and builds with `/MT` (static MSVC runtime, `VC-WIN64A`
target, `no-asm`). The script is idempotent — it skips the build if
`thirdparty\openssl-windows\x64\lib\libssl.lib` already exists (pass `-Force`
to rebuild).

Output: `binaries/windows/<version>/torrent-rasterbar.dll`

## Android (NDK arm64-v8a)

Requires Android NDK 26.3.11579264 with `ANDROID_NDK_HOME` set.

```sh
sudo apt-get install -y cmake ninja-build ccache libboost-dev

# Build static OpenSSL for arm64 (output: thirdparty/openssl-android/arm64-v8a/)
bash scripts/build_openssl_android.sh

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
# Copy Boost to a non-system path: the NDK toolchain strips /usr/include
mkdir -p /tmp/boost-include && cp -r /usr/include/boost /tmp/boost-include/
BOOST_ROOT="/tmp/boost-include"
OPENSSL_ROOT="$PWD/thirdparty/openssl-android/arm64-v8a"

cmake --preset android \
  -DLTD_BINARY_LAYOUT_VERSION="$VERSION" \
  -DLTD_BOOST_HEADERS_ROOT="$BOOST_ROOT" \
  -DBoost_INCLUDE_DIR="$BOOST_ROOT" \
  -DBoost_INCLUDE_DIRS="$BOOST_ROOT" \
  -DBOOST_ROOT="$BOOST_ROOT" \
  -DBOOST_INCLUDEDIR="$BOOST_ROOT" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT" \
  -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_ROOT/lib/libcrypto.a" \
  -DOPENSSL_SSL_LIBRARY="$OPENSSL_ROOT/lib/libssl.a" \
  -DOPENSSL_INCLUDE_DIR="$OPENSSL_ROOT/include"
cmake --build --preset android --parallel
```

`build_openssl_android.sh` downloads OpenSSL 3.4.1 and cross-compiles it for
`android-arm64` (`-D__ANDROID_API__=24`). It is idempotent — pass `--force`
as a second argument to force a rebuild.

Output: `binaries/android/<version>/libtorrent-rasterbar.so`

## iOS (arm64)

Requires macOS with Xcode installed.

```sh
brew install cmake ninja ccache boost

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
BOOST_INC="$(brew --prefix boost)/include"

cmake --preset ios \
  -DLTD_BOOST_HEADERS_ROOT="$BOOST_INC" \
  -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset ios --parallel
```

OpenSSL is disabled for iOS (`CMAKE_DISABLE_FIND_PACKAGE_OpenSSL=ON` in the
preset); libtorrent falls back to its built-in crypto implementation.

Output: `binaries/ios/<version>/Release/libtorrent-rasterbar.a`

## Dart checks

```sh
dart pub get
dart analyze
dart test
```

## CI / CD

### Tests workflow (`.github/workflows/tests.yml`)

Triggered on every push to `main`, on pull requests, and on manual dispatch.
Builds Linux, macOS, and Windows using the shared composite action at
`.github/actions/build-native/`, then runs `dart analyze` and `dart test` on
each runner.

### Release workflow (`.github/workflows/release.yml`)

Triggered by pushing a `v*` tag or via manual dispatch. Builds all five
platforms in parallel (Linux, macOS, Windows, Android, iOS), then the
`publish-release` job:

1. Downloads all build artifacts.
2. Renames them to the canonical release asset names:

   | Asset file                         | Platform      |
   | ---------------------------------- | ------------- |
   | `linux-libtorrent-rasterbar.so`    | Linux         |
   | `macos-libtorrent-rasterbar.dylib` | macOS         |
   | `windows-torrent-rasterbar.dll`    | Windows       |
   | `android-libtorrent-rasterbar.so`  | Android arm64 |
   | `ios-libtorrent-rasterbar.a`       | iOS arm64     |

3. Creates or updates the GitHub release for the tag (using `gh release create`
   / `gh release upload --clobber`) with auto-generated notes.

### Releasing a new version

1. Bump `version` in `pubspec.yaml`.
2. Run the release helper (requires a clean working tree):

   ```sh
   dart scripts/release.dart
   ```

   This reads the version from `pubspec.yaml`, checks for uncommitted changes,
   creates a local `v<version>` tag, pushes the branch, then pushes the tag —
   which triggers the Release workflow automatically.
