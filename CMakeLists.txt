# ---------------------------------------------------------------------------- #
# Define cmake project cmake工程定义
# ---------------------------------------------------------------------------- #
cmake_minimum_required(VERSION 3.20)

# 指定Unicode字符集
add_definitions(-DUNICODE -D_UNICODE)

# 工程定义
project(communication_sdk
    VERSION 1.0.0
    LANGUAGES C CXX
    DESCRIPTION "communication sdk"
)

# 必须在工程定义之后包含project模块
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(project)

# ---------------------------------------------------------------------------- #
# Define global variables 定义全局变量
# ---------------------------------------------------------------------------- #

# 设置目标平台
string(TOLOWER ${CMAKE_SYSTEM_NAME} TARGET_PLATFORM)

# 设置目标架构
set(TARGET_ARCH ${CMAKE_SYSTEM_PROCESSOR})
if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_ARCH x64)
        set(INSTALL_ARCH x64)
    else()
        set(TARGET_ARCH x86)
        set(INSTALL_ARCH x86)
    endif()
elseif(APPLE)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_ARCH x86_64)
        set(INSTALL_ARCH x64)
    endif()
    set(CMAKE_OSX_ARCHITECTURES ${TARGET_ARCH})
elseif(UNIX)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_ARCH x64)
        set(INSTALL_ARCH x64)
    else()
        set(TARGET_ARCH x86)
        set(INSTALL_ARCH x86)
    endif()
elseif(ANDROID)
endif()

# 设置构建类型
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

message(STATUS "Build target, mode: ${BUILD_MODE}, platform: ${TARGET_PLATFORM}, arch: ${TARGET_ARCH}, build type: ${BUILD_TYPE}")

if(WIN32)
    set(TARGET_NAME lib_CommunicationSDK)
elseif(APPLE)
    set(TARGET_NAME CommunicationSDK)
elseif(UNIX)
    set(TARGET_NAME CommunicationSDK)
else()
    set(TARGET_NAME CommunicationSDK)
endif()

# 设置全局目录变量
set(BIN_DIR ${PROJECT_SOURCE_DIR}/bin)
set(CODE_DIR ${PROJECT_SOURCE_DIR}/code)
set(SRC_DIR ${CODE_DIR}/src)
set(INTERFACE_DIR ${CODE_DIR}/interface)
set(VERSION_DIR ${CODE_DIR}/version)
set(APP_DIR ${CODE_DIR}/app)
set(EXAMPLE_DIR ${PROJECT_SOURCE_DIR}/example)
set(3TH_DIR ${PROJECT_SOURCE_DIR}/3th)
set(BIN_OUTPUT_DIR ${BIN_DIR}/${INSTALL_ARCH})
set(CPACKAGE_FILE ${PROJECT_SOURCE_DIR}/cpackage.json)
set(CONFIG_DIR ${PROJECT_SOURCE_DIR}/config)
set(PUBLIC_DOC_DIR ${PROJECT_SOURCE_DIR}/doc/public)

# 设置全局文件变量
set(VERSION_HEADER_TPL_FILE ${VERSION_DIR}/version.h.in)
set(VERSION_HEADER_FILE ${VERSION_DIR}/version.h)
set(VERSION_RC_TPL_FILE ${VERSION_DIR}/win_version_info.rc.in)
set(VERSION_RC_FILE ${VERSION_DIR}/win_version_info.rc)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BIN_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${BIN_OUTPUT_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${BIN_OUTPUT_DIR})

message(STATUS "CMAKE_RUNTIME_OUTPUT_DIRECTORY: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

# 设置install变量
if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/install)
endif()
set(INSTALL_BIN_NAME  bin/${INSTALL_ARCH})
set(INSTALL_INCLUDE_NAME inlude)
set(INSTALL_LIBRARY_NAME lib/${INSTALL_ARCH})
set(INSTALL_CONFIG_NAME config)
set(INSTALL_DOC_NAME doc)
set(INSTALL_EXAMPLE_NAME example)
set(INSTALL_RESOURCE_NAME resource)

# ---------------------------------------------------------------------------- #
# Config version info 配置版本信息
# ---------------------------------------------------------------------------- #

if(DEFINED BUILD_MODE AND ${BUILD_MODE} STREQUAL "dev")
    set(GIT_COMMIT_COUNT 11110)
    set(GIT_BRANCH D)
    set(GIT_COMMIT develop)
    set(GIT_VERSION "${GIT_COMMIT_COUNT}-${GIT_BRANCH}-${GIT_COMMIT}")
    file(WRITE ${PROJECT_BINARY_DIR}/git_version
        "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${GIT_VERSION}"
    )
else()
    include(get_git_version)
endif()
message(STATUS "${PROJECT_NAME} version: ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${GIT_VERSION}")

# version file
configure_file("${VERSION_HEADER_TPL_FILE}" "${VERSION_HEADER_FILE}")

# 生成windows版本信息文件
if(WIN32)
    configure_file("${VERSION_RC_TPL_FILE}" "${VERSION_RC_FILE}")
endif()

message(STATUS "VERSION_RC_FILE: ${VERSION_RC_FILE}")

# ---------------------------------------------------------------------------- #
# Project add library target 添加库目标
# ---------------------------------------------------------------------------- #

if(WIN32)
    set_target_properties(${TS_LIBRARY_TARGET_NAME} PROPERTIES MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# 设置源代码
file(GLOB_RECURSE interface_code_files ${INTERFACE_DIR}/*.*)
file(GLOB_RECURSE src_code_files ${SRC_DIR}/*.*)

# 对源码进行分组
source_group(interface FILES ${interface_code_files})
source_group(src FILES ${src_code_files})
source_group(version FILES ${VERSION_RC_FILE})

# 添加库目标
add_library(${TARGET_NAME} SHARED)
target_sources(${TARGET_NAME}
    PRIVATE
    ${interface_code_files}
    ${src_code_files}
    ${VERSION_RC_FILE}
)
target_include_directories(${TARGET_NAME}
    PRIVATE
    ${CODE_DIR}
    ${INTERFACE_DIR}
    ${SRC_DIR}
)

target_compile_definitions(${TARGET_NAME} PRIVATE DLL_EXPORT PUBLIC "$<$<CONFIG:DEBUG>:_DEBUG>")
target_compile_definitions(${TARGET_NAME} PUBLIC cxx_std_17)

if(WIN32)
    set_target_properties(${TARGET_NAME} PROPERTIES MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif(WIN32)

# ---------------------------------------------------------------------------- #
# Target link 3th library 链接第三方库
# ---------------------------------------------------------------------------- #

target_add_third_party_from_config(${TARGET_NAME} ${CPACKAGE_FILE} ${3TH_DIR} ${TARGET_PLATFORM} ${INSTALL_BIN_NAME})

# ---------------------------------------------------------------------------- #
# Project add runnable target 添加可执行目标
# ---------------------------------------------------------------------------- #

# 添加可执行应用
add_subdirectory(${APP_DIR}/cmake_template_app)

# 添加示例应用
add_subdirectory(${EXAMPLE_DIR})

# ---------------------------------------------------------------------------- #
# Install 设置安装路径
# ---------------------------------------------------------------------------- #

install(TARGETS ${TARGET_NAME} 
    RUNTIME DESTINATION ${INSTALL_BIN_NAME} 
    LIBRARY DESTINATION ${INSTALL_BIN_NAME}
    ARCHIVE DESTINATION ${INSTALL_LIBRARY_NAME}
)
install(DIRECTORY ${INTERFACE_DIR}/ DESTINATION ${INSTALL_INCLUDE_NAME})
install(DIRECTORY ${PUBLIC_DOC_DIR}/ DESTINATION ${INSTALL_DOC_NAME})
install(DIRECTORY ${CONFIG_DIR}/ DESTINATION ${INSTALL_CONFIG_NAME})

# 设置git版本install路径
install(FILES ${CMAKE_BINARY_DIR}/git_version DESTINATION .)
# 设置符号文件install路径
if(WIN32)
    set(PDB_FILES ${BIN_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}/${TARGET_NAME}.pdb)
    install(FILES ${PDB_FILES} DESTINATION ${INSTALL_BIN_NAME})
endif()