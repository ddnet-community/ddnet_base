cmake_minimum_required(VERSION 3.12...3.27.4)

set(CMAKE_CXX_STANDARD 20)

project(ddnet_base)

set(BASE_SRC
	src/ddnet_base/base/hash_libtomcrypt.cpp
	src/ddnet_base/base/str.cpp
	src/ddnet_base/base/color.cpp
	src/ddnet_base/base/system.cpp
	src/ddnet_base/base/hash_openssl.cpp
	src/ddnet_base/base/color.rs
	src/ddnet_base/base/fs.cpp
	src/ddnet_base/base/hash_bundled.cpp
	src/ddnet_base/base/crashdump.cpp
	src/ddnet_base/base/hash.cpp
	src/ddnet_base/base/bezier.cpp
	src/ddnet_base/base/unicode
	src/ddnet_base/base/unicode/confusables.cpp
	src/ddnet_base/base/unicode/tolower_data.cpp
	src/ddnet_base/base/unicode/tolower.cpp
	src/ddnet_base/base/log.cpp
	src/ddnet_base/engine/external/md5/md5.cpp
)

add_library(ddnet_base ${BASE_SRC})
target_include_directories(ddnet_base PRIVATE src/ddnet_base)
target_include_directories(ddnet_base
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:ddnet_base>
)

set(LIB_PUBLIC_HEADERS_BASE
	src/ddnet_base/base/str.h
	src/ddnet_base/base/hash_ctxt.h
	src/ddnet_base/base/vmath.h
	src/ddnet_base/base/logger.h
	src/ddnet_base/base/system.h
	src/ddnet_base/base/detect.h
	src/ddnet_base/base/dynamic.h
	src/ddnet_base/base/hash.h
	src/ddnet_base/base/rust.h
	src/ddnet_base/base/tl/threading.h
	src/ddnet_base/base/types.h
	src/ddnet_base/base/lock.h
	src/ddnet_base/base/fs.h
	src/ddnet_base/base/bezier.h
	src/ddnet_base/base/log.h
	src/ddnet_base/base/unicode/confusables_data.h
	src/ddnet_base/base/unicode/confusables.h
	src/ddnet_base/base/unicode/tolower_data.h
	src/ddnet_base/base/color.h
	src/ddnet_base/base/math.h
)

set(LIB_PUBLIC_HEADERS_ENGINE_EXTERNAL
	src/ddnet_base/engine/external/md5/md5.h
)

if(APPLE)
	find_library(CORE_FOUNDATION_LIBRARY CoreFoundation REQUIRED)
	target_link_libraries(ddnet_base PUBLIC ${CORE_FOUNDATION_LIBRARY})
endif()

if(WIN32)
	# See https://learn.microsoft.com/en-us/windows/win32/winprog/using-the-windows-headers
	target_compile_definitions(ddnet_base PRIVATE NOMINMAX) # windows.h shouldn't define min/max macros
	target_compile_definitions(ddnet_base PRIVATE WIN32_LEAN_AND_MEAN) # windows.h shouldn't define the name IStorage
	# 0x0501 (Windows XP) is required for mingw to get getaddrinfo to work
	# 0x0600 (Windows Vista) is required to use RegGetValueW and RegDeleteTreeW
	target_compile_definitions(ddnet_base PRIVATE NTDDI_VERSION=0x06000000) # Minimum OS version (new macro, since Vista)
	target_compile_definitions(ddnet_base PRIVATE _WIN32_WINNT=0x0600) # Minimum OS version (old macro, both must be defined)
	target_compile_definitions(ddnet_base PRIVATE UNICODE) # Windows headers
	target_compile_definitions(ddnet_base PRIVATE _UNICODE) # C-runtime
endif()

if(MSVC)
	target_compile_options(ddnet_base PRIVATE /Zc:__cplusplus) # Fixes the __cplusplus macro
	target_compile_options(ddnet_base PRIVATE /MP) # Use multiple cores
	target_compile_options(ddnet_base PRIVATE /EHsc) # Only catch C++ exceptions with catch.
	target_compile_options(ddnet_base PRIVATE /GS) # Protect the stack pointer.
	target_compile_options(ddnet_base PRIVATE /wd4996) # Use of non-_s functions.
	target_compile_options(ddnet_base PRIVATE /utf-8) # Use UTF-8 for source files.
endif()

# install
include(GNUInstallDirs)
install(TARGETS ddnet_base
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION lib)
install(FILES ${LIB_PUBLIC_HEADERS_BASE} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ddnet_base/base)
install(FILES ${LIB_PUBLIC_HEADERS_ENGINE_EXTERNAL} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ddnet_base/engine/external)

### uninstall
configure_file(cmake/cmake_uninstall.cmake.in cmake_uninstall.cmake IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
