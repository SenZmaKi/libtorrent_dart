cmake_minimum_required(VERSION 3.20)

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
endif()

# ──────────────────────────────────────────────────────────────────────────────
# Static OpenSSL (macOS/Linux) — link encryption into the wrapper so the
# output dylib/so has no dependency on a Homebrew or distro OpenSSL path.
# ──────────────────────────────────────────────────────────────────────────────

if(NOT ANDROID AND NOT WIN32)
  set(OPENSSL_USE_STATIC_LIBS TRUE CACHE BOOL "" FORCE)
  # Help CMake find the Homebrew static libs on macOS
  if(APPLE)
    set(OPENSSL_ROOT_DIR "/opt/homebrew/opt/openssl@3" CACHE PATH "" FORCE)
  endif()
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

if(IOS)
  set_target_properties(libtorrent_dart PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/ios"
  )
elseif(APPLE)
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/macos"
  )
elseif(ANDROID)
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/android"
  )
elseif(WIN32)
  set_target_properties(libtorrent_dart PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/windows"
    OUTPUT_NAME torrent-rasterbar
  )
else()
  # Linux / other POSIX
  set_target_properties(libtorrent_dart PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${LTD_OUTPUT_DIR}/linux"
  )
endif()
