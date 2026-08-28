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
binaries/linux/0.3.2/x64/libtorrent-rasterbar.so
```

This prevents accidentally loading stale binaries from an older package version.
Every multi-architecture platform adds an architecture directory. Flutter runs
native-asset hooks once per target architecture and selects the matching thin
binary:

```
binaries/<platform>/<package-version>/<architecture>/<binary-name>
```

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
- Ninja (`brew install ninja` / `apt install ninja-build` / `choco install ninja`),
  except for iOS, which uses Xcode
- ccache (`brew install ccache` / `apt install ccache` / `choco install ccache`),
  except for the iOS Xcode build
- Boost headers 1.80+ (see per-platform instructions below)
- Dart SDK ≥ 3.10.0
- Git with submodules:

```sh
git clone --recursive https://github.com/SenZmaKi/libtorrent_dart.git
cd libtorrent_dart
```

## CMake Presets

The project ships a `CMakePresets.json` with ready-made presets. All build
output lands in `cmake_build/<preset-name>/` and binaries are written to
`binaries/<platform>/<version>/`.

| Preset        | Platform    | Generator | Notes                                                 |
| ------------- | ----------- | --------- | ----------------------------------------------------- |
| `linux-x64`   | Linux x64   | Ninja     | Native x64 runner, gcc/clang, ccache, Boost headers   |
| `linux-arm64` | Linux arm64 | Ninja     | Native arm64 runner, gcc/clang, ccache, Boost headers |
| `macos-arm64` | macOS arm64 | Ninja     | Apple Silicon runner and Homebrew dependencies       |
| `macos-x64`   | macOS x64   | Ninja     | Intel runner and Homebrew dependencies               |
| `windows-x64` | Windows x64 | Ninja     | Native x64 MSVC runner, static MSVC runtime           |
| `windows-arm64` | Windows arm64 | Ninja | Native arm64 MSVC runner, static MSVC runtime         |
| `android-armv7` | Android armeabi-v7a | Ninja | API 24, NDK toolchain, c++\_static, ccache       |
| `android-arm64` | Android arm64-v8a | Ninja | API 24, NDK toolchain, c++\_static, ccache       |
| `android-x64` | Android x86_64 | Ninja | API 24, NDK toolchain, c++\_static, ccache           |
| `ios`         | iOS         | Xcode     | arm64, deployment target 13.0, bundled OpenSSL 3.4.1  |

## Linux

```sh
sudo apt-get install -y cmake ninja-build ccache libboost-dev libssl-dev

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
case "$(uname -m)" in
  x86_64) PRESET="linux-x64" ;;
  aarch64|arm64) PRESET="linux-arm64" ;;
  *) echo "Unsupported Linux architecture" >&2; exit 1 ;;
esac
cmake --preset "$PRESET" -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset "$PRESET" --parallel
```

Output: `binaries/linux/<version>/<x64|arm64>/libtorrent-rasterbar.so`

## macOS

```sh
brew install cmake ninja ccache boost openssl@3

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
BOOST_INC="$(brew --prefix boost)/include"
OPENSSL_ROOT="$(brew --prefix openssl@3)"
case "$(uname -m)" in
  arm64) PRESET="macos-arm64" ;;
  x86_64) PRESET="macos-x64" ;;
  *) echo "Unsupported macOS architecture" >&2; exit 1 ;;
esac
cmake --preset "$PRESET" \
  -DLTD_BOOST_HEADERS_ROOT="$BOOST_INC" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT" \
  -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset "$PRESET" --parallel
```

Output: `binaries/macos/<version>/<arm64|x64>/libtorrent-rasterbar.dylib`

Build each slice on its matching architecture. Do not merge them with `lipo`;
Flutter's native-assets pipeline selects both thin inputs and creates the
universal application binary.

## Windows (MSVC)

**Requirements:** Visual Studio 2022 with the C++ workload. Run all commands
from a **VS x64 Developer Command Prompt** (or after `ilammy/msvc-dev-cmd`).
MinGW / LLVM-MinGW are not supported.

```powershell
# Install Boost (places headers under C:\local\boost_*)
choco install boost-msvc-14.3 -y

$architecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }

# Build matching static OpenSSL output under thirdparty\openssl-windows\.
.\scripts\build_openssl_windows.ps1 -Architecture $architecture

$boostDir = Get-ChildItem 'C:\local' -Directory | Where-Object { $_.Name -like 'boost_*' } | Select-Object -First 1
$version  = (Select-String pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$OPENSSL  = "$(Get-Location)\thirdparty\openssl-windows\$architecture"
$preset = "windows-$architecture"

cmake --preset $preset `
  -DLTD_BOOST_HEADERS_ROOT="$($boostDir.FullName)" `
  -DLTD_BINARY_LAYOUT_VERSION="$version" `
  -DOPENSSL_ROOT_DIR="$OPENSSL" `
  -DOPENSSL_SSL_LIBRARY="$OPENSSL\lib\libssl.lib" `
  -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL\lib\libcrypto.lib" `
  -DOPENSSL_INCLUDE_DIR="$OPENSSL\include"
cmake --build --preset $preset --parallel
```

`build_openssl_windows.ps1` downloads OpenSSL 3.4.1, installs Strawberry Perl
via choco if needed, and builds with `/MT` (static MSVC runtime,
`VC-WIN64A`/`VC-WIN64-ARM`, `no-asm`). The script is idempotent and maintains
independent x64 and arm64 output directories (pass `-Force` to rebuild).

Output: `binaries/windows/<version>/<x64|arm64>/torrent-rasterbar.dll`

## Android (NDK armeabi-v7a, arm64-v8a, and x86_64)

Requires Android NDK 26.3.11579264 with `ANDROID_NDK_HOME` set.

```sh
sudo apt-get install -y cmake ninja-build ccache libboost-dev

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
# Copy Boost to a non-system path: the NDK toolchain strips /usr/include
mkdir -p /tmp/boost-include && cp -r /usr/include/boost /tmp/boost-include/
BOOST_ROOT="/tmp/boost-include"
for ABI in armeabi-v7a arm64-v8a x86_64; do
  case "$ABI" in
    armeabi-v7a) PRESET="android-armv7" ;;
    arm64-v8a) PRESET="android-arm64" ;;
    x86_64) PRESET="android-x64" ;;
  esac
  bash scripts/build_openssl_android.sh 3.4.1 "$ABI"
  OPENSSL_ROOT="$PWD/thirdparty/openssl-android/$ABI"

  cmake --preset "$PRESET" \
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
  cmake --build --preset "$PRESET" --parallel
done
```

`build_openssl_android.sh` downloads OpenSSL 3.4.1 and cross-compiles it for
the requested ABI (`-D__ANDROID_API__=24`). It is idempotent; pass `--force`
as the third argument to force a rebuild.

Output: `binaries/android/<version>/<armeabi-v7a|arm64-v8a|x86_64>/libtorrent-rasterbar.so`

## iOS (arm64)

Requires macOS with Xcode installed.

```sh
brew install cmake boost

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
BOOST_INC="$(brew --prefix boost)/include"
OPENSSL_ROOT="$PWD/thirdparty/openssl-ios/arm64"

bash scripts/build_openssl_ios.sh 3.4.1

cmake --preset ios \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL=OFF \
  -DLTD_BOOST_HEADERS_ROOT="$BOOST_INC" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT" \
  -DOPENSSL_SSL_LIBRARY="$OPENSSL_ROOT/lib/libssl.a" \
  -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_ROOT/lib/libcrypto.a" \
  -DOPENSSL_INCLUDE_DIR="$OPENSSL_ROOT/include" \
  -DLTD_BINARY_LAYOUT_VERSION="$VERSION"
cmake --build --preset ios --parallel
```

`build_openssl_ios.sh` downloads OpenSSL 3.4.1 and builds an arm64 static iOS
archive. The CMake bundle target combines the Dart wrapper, libtorrent,
`libssl.a`, and `libcrypto.a` into one consumer-facing archive.

Output: `binaries/ios/<version>/libtorrent-rasterbar.a`

The iOS workflow verifies that the archive is larger than the thin wrapper,
contains more than two members, contains arm64 code, exports `lt_version` and
`OPENSSL_init_ssl`, and links successfully into a minimal arm64 iOS consumer.

## Dart checks

```sh
dart pub get
dart analyze
dart test
```

## CI / CD

### Tests workflow (`.github/workflows/tests.yml`)

Triggered on every push to `main`, on pull requests, and on manual dispatch.
Builds and tests Linux, macOS, and Windows on native x64 and arm64 runners.
Android armeabi-v7a, arm64-v8a, and x86_64 cross-builds run through the Android composite
action; host Dart tests cannot load Android ELF binaries.

Native and Android jobs share architecture-scoped caches between the Tests and
Release workflows. Dart package downloads are keyed by platform, architecture,
and `pubspec.yaml`; ccache entries are compressed, capped at 1 GiB per target,
and keyed by commit with an architecture-specific restore prefix. Android
identifies the freshly installed NDK compiler by content instead of timestamp,
so equivalent toolchain installs can reuse compiler results. Android, Windows,
and iOS OpenSSL archives are keyed by OpenSSL/toolchain target and the relevant
build-script hash. The iOS Xcode-generator build intentionally has no ccache
entry: CMake compiler launchers only apply to Makefile and Ninja generators.

Linux, Android, Windows, and macOS builds validate the produced architecture and
the exported `lt_version` symbol. Dynamic-library builds also reject unbundled
libtorrent, OpenSSL, and machine-local Homebrew dependencies. The iOS job uses
the archive and consumer-link checks described above.

### Release workflow (`.github/workflows/release.yml`)

Triggered by pushing a `v*` tag or via manual dispatch. Builds all five
platforms in parallel (Linux, macOS, Windows, Android, iOS), then runs the
`publish-release` job:

1. Downloads all build artifacts.
2. Renames them to the canonical release asset names:

   | Asset file                                    | Platform      |
   | --------------------------------------------- | ------------- |
   | `linux-x64-libtorrent-rasterbar.so`           | Linux x64     |
   | `linux-arm64-libtorrent-rasterbar.so`         | Linux arm64   |
   | `macos-arm64-libtorrent-rasterbar.dylib`      | macOS arm64   |
   | `macos-x64-libtorrent-rasterbar.dylib`        | macOS x64     |
   | `windows-x64-torrent-rasterbar.dll`           | Windows x64   |
   | `windows-arm64-torrent-rasterbar.dll`         | Windows arm64 |
   | `android-armeabi-v7a-libtorrent-rasterbar.so` | Android ARMv7 |
   | `android-arm64-v8a-libtorrent-rasterbar.so`   | Android arm64 |
   | `android-x86_64-libtorrent-rasterbar.so`      | Android x64   |
   | `ios-libtorrent-rasterbar.a`                  | iOS arm64     |

3. Creates or updates the GitHub release for the tag (using `gh release create`
   / `gh release upload --clobber`) with auto-generated notes.
4. For a pushed `v*` tag only, publishes the matching Dart package through
   pub.dev's GitHub OIDC integration after the release assets exist. Manual
   dispatch does not run the pub.dev publication job.

For manual dispatch, the selected ref's `github.ref_name` is used as the GitHub
release name. Select an existing version tag when manually rebuilding release
assets; dispatching from a branch would use that branch name as the release
name.

### Releasing a new version

1. Bump `version` in `pubspec.yaml`.
2. Run the release helper (requires a clean working tree):

   ```sh
   dart scripts/release.dart
   ```

   This reads the version from `pubspec.yaml`, checks for uncommitted changes,
   creates a local `v<version>` tag, pushes the branch, then pushes the tag —
   which triggers the Release workflow automatically.

See [PUBLISHING.md](PUBLISHING.md) for the one-time pub.dev setup and the full
publishing contract.
