cmake_minimum_required(VERSION 3.20)

if(POLICY CMP0167)
  # thirdparty/libtorrent currently relies on FindBoost behavior.
  cmake_policy(SET CMP0167 OLD)
endif()

project(libtorrent_dart LANGUAGES C CXX)

set(LTD_DART_LIBRARY_TYPE SHARED)
if(IOS)
  # iOS consumers typically link static artifacts into the app binary.
  set(LTD_DART_LIBRARY_TYPE STATIC)
endif()

# ──────────────────────────────────────────────────────────────────────────────
# Options
# ──────────────────────────────────────────────────────────────────────────────

set(LTD_BOOST_HEADERS_ROOT "/opt/homebrew/include" CACHE PATH
  "Directory that contains boost/ headers (e.g. /opt/homebrew/include)")

set(LTD_OUTPUT_DIR "${CMAKE_CURRENT_LIST_DIR}/binaries" CACHE PATH
  "Root directory where platform-specific prebuilt libraries are placed")
set(LTD_BINARY_LAYOUT_VERSION "" CACHE STRING
  "Optional version segment under each platform output directory")

# ──────────────────────────────────────────────────────────────────────────────
# Boost headers
# ──────────────────────────────────────────────────────────────────────────────

if(EXISTS "${LTD_BOOST_HEADERS_ROOT}/boost/version.hpp")
  set(Boost_INCLUDE_DIR    "${LTD_BOOST_HEADERS_ROOT}" CACHE PATH "" FORCE)
  set(Boost_INCLUDE_DIRS   "${LTD_BOOST_HEADERS_ROOT}" CACHE PATH "" FORCE)
  set(BOOST_ROOT           "${LTD_BOOST_HEADERS_ROOT}" CACHE PATH "" FORCE)
  set(BOOST_INCLUDEDIR     "${LTD_BOOST_HEADERS_ROOT}" CACHE PATH "" FORCE)
  set(Boost_NO_SYSTEM_PATHS OFF CACHE BOOL "" FORCE)
  # Keep Boost headers available even in cross-compiles (Android toolchain may
  # not pick host include paths unless explicitly injected).
  include_directories(BEFORE "${LTD_BOOST_HEADERS_ROOT}")
  if(ANDROID)
    # The NDK toolchain adds host paths (e.g. /usr/include) to
    # CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES, causing CMake to silently strip
    # them from include_directories() output.  Force Boost into the compile
    # flags directly to bypass that deduplication.
    add_compile_options("-isystem${LTD_BOOST_HEADERS_ROOT}")
  endif()
endif()

# ──────────────────────────────────────────────────────────────────────────────
# Static OpenSSL (macOS/Linux) — link encryption into the wrapper so the
# output dylib/so has no dependency on a Homebrew or distro OpenSSL path.
# ──────────────────────────────────────────────────────────────────────────────

if(NOT ANDROID AND NOT IOS)
  set(OPENSSL_USE_STATIC_LIBS TRUE CACHE BOOL "" FORCE)
  # Provide Homebrew default; command-line -DOPENSSL_ROOT_DIR overrides this.
  # iOS passes CMAKE_DISABLE_FIND_PACKAGE_OpenSSL=ON via its CMake preset
  # so libtorrent falls back to its built-in crypto (no OpenSSL on iOS).
  # Android and Windows use cross-compiled/bundled static OpenSSL passed via
  # -DOPENSSL_ROOT_DIR (and explicit -DOPENSSL_SSL_LIBRARY / CRYPTO_LIBRARY).
  if(APPLE AND NOT OPENSSL_ROOT_DIR)
    set(OPENSSL_ROOT_DIR "/opt/homebrew/opt/openssl@3")
  endif()
  if(WIN32 AND NOT OPENSSL_ROOT_DIR)
    set(OPENSSL_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/thirdparty/openssl-windows/x64")
  endif()
endif()

# ──────────────────────────────────────────────────────────────────────────────
# Symbol visibility (non-Windows): hide all internal symbols so only the
# explicitly-annotated C API is exported.  This shrinks the export table,
# prevents ODR conflicts when libtorrent is bundled in multiple .so/.dylib
# files, and reduces binary size on Android.
# ──────────────────────────────────────────────────────────────────────────────
if(NOT WIN32)
  add_compile_options(-fvisibility=hidden -fvisibility-inlines-hidden)
endif()
if(ANDROID)
  # Dead-code elimination: split each function/variable into its own section
  # so the linker can discard unreachable ones.
  add_compile_options(-ffunction-sections -fdata-sections)
endif()

# ──────────────────────────────────────────────────────────────────────────────
# libtorrent (git submodule at thirdparty/libtorrent)
# ──────────────────────────────────────────────────────────────────────────────

# Build libtorrent as a static library so released wrapper binaries don't rely
# on an extra libtorrent shared library being present at runtime.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
# Ensure static dependencies are built with PIC so they can be linked into the
# wrapper shared library on Linux/macOS.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory(thirdparty/libtorrent thirdparty/libtorrent-build)

# ──────────────────────────────────────────────────────────────────────────────
# libtorrent_dart shared library (the FFI wrapper)
# ──────────────────────────────────────────────────────────────────────────────

add_library(libtorrent_dart ${LTD_DART_LIBRARY_TYPE} src/c/library.cpp)

# ──────────────────────────────────────────────────────────────────────────────
# Windows Portability Fix: Static Linking
# ──────────────────────────────────────────────────────────────────────────────
if(WIN32)
  if(NOT MSVC)
    message(FATAL_ERROR
      "Only MSVC (cl.exe) is supported on Windows.\n"
      "Open a VS x64 Developer Command Prompt or use the 'windows' CMake preset."
    )
  endif()

  # Core Windows networking and crypto libs
  target_link_libraries(libtorrent_dart PRIVATE iphlpapi ws2_32 bcrypt)
endif()
target_include_directories(libtorrent_dart PRIVATE src/c)

target_link_libraries(libtorrent_dart PRIVATE torrent-rasterbar)

target_compile_definitions(libtorrent_dart  PRIVATE BOOST_ASIO_DISABLE_STD_ALIGNED_ALLOC)
target_compile_definitions(torrent-rasterbar PRIVATE BOOST_ASIO_DISABLE_STD_ALIGNED_ALLOC)

set_target_properties(libtorrent_dart PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
  OUTPUT_NAME libtorrent-rasterbar
  PREFIX ""
)

# ──────────────────────────────────────────────────────────────────────────────
# Per-platform output directories and post-build fixups
# ──────────────────────────────────────────────────────────────────────────────

set(_ltd_version_suffix "")
if(NOT LTD_BINARY_LAYOUT_VERSION STREQUAL "")
  set(_ltd_version_suffix "/${LTD_BINARY_LAYOUT_VERSION}")
endif()

if(IOS)
  set_target_properties(libtorrent_dart PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/ios${_ltd_version_suffix}"
  )
elseif(APPLE)
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/macos${_ltd_version_suffix}"
  )
elseif(ANDROID)
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/android${_ltd_version_suffix}"
  )
elseif(WIN32)
  set_target_properties(libtorrent_dart PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/windows${_ltd_version_suffix}"
    ARCHIVE_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/windows${_ltd_version_suffix}"
    OUTPUT_NAME torrent-rasterbar
  )
else()
  # Linux / other POSIX
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/linux${_ltd_version_suffix}"
  )
endif()

# ──────────────────────────────────────────────────────────────────────────────
# Release binary size: strip debug info and dead code from the linked output.
# These flags only activate for Release builds via generator expressions.
# ──────────────────────────────────────────────────────────────────────────────
if(ANDROID)
  target_link_options(libtorrent_dart PRIVATE
    $<$<CONFIG:Release>:-Wl,--gc-sections>
    $<$<CONFIG:Release>:-Wl,--strip-debug>
    # Prevent symbols from statically-linked archives (libtorrent, libc++_static,
    # libssl, etc.) from leaking into the .so dynamic symbol table.
    -Wl,--exclude-libs,ALL
  )
elseif(UNIX AND NOT APPLE)
  target_link_options(libtorrent_dart PRIVATE
    $<$<CONFIG:Release>:-Wl,--strip-debug>
  )
elseif(APPLE AND NOT IOS)
  target_link_options(libtorrent_dart PRIVATE
    $<$<CONFIG:Release>:-Wl,-S>
  )
endif()
