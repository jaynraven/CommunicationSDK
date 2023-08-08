# 解析cpackage.json的内容
macro(macro_set_dep_vars cpackage_dep_json platform_name)
    string(JSON CPACKAGE_DEP_NAME GET ${cpackage_dep_json} "name")
    unset(${CPACKAGE_DEP_NAME}_NAME)
    set(${CPACKAGE_DEP_NAME}_NAME ${CPACKAGE_DEP_NAME} PARENT_SCOPE)

    string(JSON CPACKAGE_DEP_VERSION ERROR_VARIABLE error_var GET ${cpackage_dep_json} "version")
    unset(${CPACKAGE_DEP_NAME}_VERSION)
    set(${CPACKAGE_DEP_NAME}_VERSION ${CPACKAGE_DEP_VERSION} PARENT_SCOPE)

    string(JSON CPACKAGE_DEP_TAG GET ${cpackage_dep_json} "tag")
    unset(${CPACKAGE_DEP_NAME}_TAG)
    set(${CPACKAGE_DEP_NAME}_TAG ${CPACKAGE_DEP_TAG} PARENT_SCOPE)

    string(JSON CPACKAGE_DEP_ACCESS GET ${cpackage_dep_json} "access")
    unset(${CPACKAGE_DEP_NAME}_ACCESS)
    set(${CPACKAGE_DEP_NAME}_ACCESS ${CPACKAGE_DEP_ACCESS} PARENT_SCOPE)

    string(JSON CPACKAGE_DEP_URL GET ${cpackage_dep_json} "url")
    unset(${CPACKAGE_DEP_NAME}_URL)
    set(${CPACKAGE_DEP_NAME}_URL ${CPACKAGE_DEP_URL} PARENT_SCOPE)

    unset(${CPACKAGE_DEP_NAME}_PLATFORM)
    set(${CPACKAGE_DEP_NAME}_PLATFORM ${platform_name} PARENT_SCOPE)
endmacro(macro_set_dep_vars)

# 解析cpackage.json的内容
function(parse_cpackage_json_file cpackage_file cpackage_name cpackage_version cpackage_tag cpackage_deps platform_name)
    if (EXISTS ${cpackage_file})
        file(READ ${cpackage_file} CPACKAGE_VALUE)

        string(JSON CPACKAGE_NAME GET ${CPACKAGE_VALUE} "name")
        set(${cpackage_name} ${CPACKAGE_NAME} PARENT_SCOPE)

        string(JSON CPACKAGE_VERSION GET ${CPACKAGE_VALUE} "version")
        set(${cpackage_version} ${CPACKAGE_VERSION} PARENT_SCOPE)

        string(JSON CPACKAGE_TAG ERROR_VARIABLE error_var GET ${CPACKAGE_VALUE} "tag")
        set(${cpackage_tag} ${CPACKAGE_TAG} PARENT_SCOPE)

        string(JSON CPACKAGE_DEPENDENCIES GET ${CPACKAGE_VALUE} "dependencies")
        string(JSON CPACKAGE_DEPENDENCIES_NUM LENGTH ${CPACKAGE_VALUE} "dependencies")
        if(CPACKAGE_DEPENDENCIES_NUM GREATER 0)
            string(JSON CPACKAGE_COMMON_DEPENDENCIES_NUM LENGTH ${CPACKAGE_DEPENDENCIES} "common")
            if(CPACKAGE_COMMON_DEPENDENCIES_NUM GREATER 0)
                math(EXPR CPACKAGE_COMMON_DEPENDENCIES_NUM "${CPACKAGE_COMMON_DEPENDENCIES_NUM} - 1")
                foreach(CPACKAGE_INDEX RANGE ${CPACKAGE_COMMON_DEPENDENCIES_NUM})
                    string(JSON CPACKAGE_DEP GET ${CPACKAGE_DEPENDENCIES} "common" ${CPACKAGE_INDEX})
                    macro_set_dep_vars(${CPACKAGE_DEP} "common")
                    list(APPEND CPACKAGE_DEPS ${CPACKAGE_DEP_NAME})
                endforeach()
            endif()

            string(JSON CPACKAGE_PLATFROM_DEPENDENCIES_NUM LENGTH ${CPACKAGE_DEPENDENCIES} ${platform_name})
            if(CPACKAGE_PLATFROM_DEPENDENCIES_NUM GREATER 0)
                math(EXPR CPACKAGE_PLATFROM_DEPENDENCIES_NUM "${CPACKAGE_PLATFROM_DEPENDENCIES_NUM} - 1")
                foreach(CPACKAGE_INDEX RANGE ${CPACKAGE_PLATFROM_DEPENDENCIES_NUM})
                    string(JSON CPACKAGE_DEP GET ${CPACKAGE_DEPENDENCIES} ${platform_name} ${CPACKAGE_INDEX})
                    macro_set_dep_vars(${CPACKAGE_DEP} ${platform_name})
                    list(APPEND CPACKAGE_DEPS ${CPACKAGE_DEP_NAME})
                endforeach()
            endif()

            set(${cpackage_deps} ${CPACKAGE_DEPS} PARENT_SCOPE)
        endif()
    endif()
endfunction(parse_cpackage_json_file)

# 向工程添加库项目，即在src下的项目，生成静态库或动态库，并自动配置源代码组
function(project_add_target_library_autogroup target_name build_type code_dir version_file_ref)
    set(src_dir ${code_dir}/src)
    file(GLOB_RECURSE source_files ${src_dir}/*.cpp)
    file(GLOB_RECURSE header_files ${src_dir}/*.h ${src_dir}/*.hpp)

    set(interface_dir ${code_dir}/interface)
    file(GLOB_RECURSE interface_files ${interface_dir}/*.h ${interface_dir}/*.hpp)

    source_group(TREE ${src_dir} PREFIX src FILES ${source_files})
    source_group(TREE ${src_dir} PREFIX src FILES ${header_files})
    source_group(TREE ${interface_dir} PREFIX interface FILES ${interface_files})
    
    set(library_files ${source_files} ${header_files} ${interface_files} ${${version_file_ref}})
    add_library(${target_name} ${build_type} ${library_files})
    target_include_directories(${target_name} 
        PRIVATE ${src_dir}
        PRIVATE ${code_dir}
        PRIVATE ${code_dir}/version)
    target_compile_definitions(${target_name} PRIVATE DLL_EXPORT)
    target_compile_features(${target_name} PUBLIC cxx_std_17)
endfunction(project_add_target_library_autogroup)

# 向工程添加可执行项目，即在可执行项目目录下的子项目，生成可执行文件
function(project_add_target_runnable target_name code_dir)
    set(app_dir ${code_dir}/app/${target_name})
    file(GLOB_RECURSE source_files ${app_dir}/*.cpp)
    file(GLOB_RECURSE header_files ${app_dir}/*.h ${app_dir}/*.hpp)

    source_group(TREE ${app_dir} PREFIX src FILES ${source_files})
    source_group(TREE ${app_dir} PREFIX src FILES ${header_files})

    set(app_files ${source_files} ${header_files})
    source_group(TREE ${app_dir} FILES ${source_files})
    source_group(TREE ${app_dir} FILES ${header_files})

    add_executable(${target_name} ${app_files})
    target_include_directories(${target_name}
        PRIVATE ${app_dir}
        PRIVATE ${code_dir}/src
        PRIVATE ${code_dir}
        PRIVATE ${code_dir}/version)
    target_compile_features(${target_name} PUBLIC cxx_std_17)
endfunction(project_add_target_runnable)

# 向工程添加示例项目，即在example目录下的子项目，生成示例可执行文件
function(project_add_target_example target_name project_dir)
    set(example_dir ${project_dir}/example)
    file(GLOB_RECURSE example_files ${example_dir}/*.cpp)

    source_group(TREE ${example_dir} PREFIX src FILES ${example_files})

    add_executable(${target_name} ${example_files})
    target_include_directories(${target_name}
        PRIVATE ${example_dir}
        PRIVATE ${project_dir}/code/src
        PRIVATE ${project_dir}/code
        PRIVATE ${project_dir}/code/version)
    target_compile_features(${target_name} PUBLIC cxx_std_17)
endfunction(project_add_target_example)

# 从git下载依赖库到本地指定位置
function(download_library_from_git library_name library_url library_tag dest_dir)
    include(FetchContent)
    FetchContent_Declare(
        ${library_name}
        GIT_REPOSITORY ${library_url}
        GIT_TAG ${library_tag}
        SOURCE_DIR ${dest_dir}/${library_name}
    )
    FetchContent_MakeAvailable(${library_name})
endfunction(download_library_from_git)

# 向目标中添加第三方库文件，即在third_party中的第三方库
function(target_add_third_party target_name library_name library_access library_version library_tag library_url third_party_dir library_deps library_platform_name third_party_install_path)
    set(library_dir ${third_party_dir}/${library_platform_name}/${library_name})

    if(NOT EXISTS ${library_dir}/cpackage.json)
        download_library_from_git(${library_name} ${library_url} ${library_tag} ${third_party_dir}/${library_platform_name})
    endif()

    set(cpackage_path ${library_dir}/cpackage.json)
    parse_cpackage_json_file(${cpackage_path} cpackage_name cpackage_version cpackage_tag cpackage_deps ${library_platform_name})
    foreach(dep ${cpackage_deps})
        set(${dep}_NAME ${${dep}_NAME} PARENT_SCOPE)
        set(${dep}_VERSION ${${dep}_VERSION} PARENT_SCOPE)
        set(${dep}_TAG ${${dep}_TAG} PARENT_SCOPE)
        set(${dep}_ACCESS ${${dep}_ACCESS} PARENT_SCOPE)
        set(${dep}_URL ${${dep}_URL} PARENT_SCOPE)
        set(${dep}_PLATFORM ${${dep}_PLATFORM} PARENT_SCOPE)
    endforeach()
    set(${library_deps} ${cpackage_deps} PARENT_SCOPE)

    list(APPEND CMAKE_MODULE_PATH ${library_dir})
    find_package(${library_name})
    if(${library_name}_FOUND)
        message(STATUS "Found library target: ${${library_name}_TARGET}, "
            "include dirs: ${${library_name}_INCLUDE_DIRS}, "
            "library dirs: ${${library_name}_LIBRARY_DIRS}, "
            "libraries: ${${library_name}_LIBRARIES}, "
            "shared libraries: ${${library_name}_SHARED_LIBRARIES_RELEASE};${${library_name}_SHARED_LIBRARIES_DEBUG}")

        if (DEFINED ${library_name}_TARGET)
            add_dependencies(${target_name} ${${library_name}_TARGET})

            if (DEFINED ${library_name}_INCLUDE_DIRS)
                target_include_directories(${target_name} ${library_access} ${${library_name}_INCLUDE_DIRS})
            endif()

            if (DEFINED ${library_name}_LIBRARY_DIRS)
                target_link_directories(${target_name} ${library_access} ${${library_name}_LIBRARY_DIRS})
            endif()
            
            if (DEFINED ${library_name}_LIBRARIES)
                target_link_libraries(${target_name} ${library_access} ${${library_name}_LIBRARIES})
            endif()

            if (CMAKE_BUILD_TYPE STREQUAL "Debug" AND DEFINED ${library_name}_SHARED_LIBRARIES_DEBUG)
                install(FILES ${${library_name}_SHARED_LIBRARIES_DEBUG} DESTINATION ${third_party_install_path})
                install(FILES ${${library_name}_SHARED_LIBRARIES_DEBUG} DESTINATION ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_BUILD_TYPE})
            elseif(DEFINED ${library_name}_SHARED_LIBRARIES_RELEASE)
                install(FILES ${${library_name}_SHARED_LIBRARIES_RELEASE} DESTINATION ${third_party_install_path})
                install(FILES ${${library_name}_SHARED_LIBRARIES_RELEASE} DESTINATION ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_BUILD_TYPE})
            endif()
        else()
            message(STATUS "${library_name}_TARGET is undefined!!!")
        endif()
    else()
        message(STATUS "${library_name} not found!!!")
    endif()
endfunction(target_add_third_party)

# 从配置文件中加载第三方库
function(target_add_third_party_from_config target_name config_path third_party_dir target_platform_name third_party_install_path)
    parse_cpackage_json_file(${config_path} cpackage_name cpackage_version cpackage_tag cpackage_deps ${target_platform_name})
    set(total_deps ${cpackage_deps})
    
    while(true)
        list(LENGTH cpackage_deps dep_number)
        if(dep_number EQUAL 0)
            break()
        endif()

        foreach(dep ${cpackage_deps})
            set(dep_name ${${dep}_NAME})
            set(dep_version ${${dep}_VERSION})
            set(dep_tag ${${dep}_TAG})
            set(dep_access ${${dep}_ACCESS})
            set(dep_url ${${dep}_URL})
            set(dep_platform ${${dep}_PLATFORM})
            
            target_add_third_party(${target_name} ${dep_name} ${dep_access} ${dep_version} ${dep_tag} ${dep_url} ${third_party_dir} sub_cpackage_deps ${dep_platform} ${third_party_install_path})
            list(REMOVE_ITEM cpackage_deps ${dep})
            foreach(subdep ${sub_cpackage_deps})
                if(NOT ${subdep} IN_LIST total_deps)
                    list(APPEND cpackage_deps ${${subdep}_NAME})
                    list(APPEND total_deps ${${subdep}_NAME})
                endif()
            endforeach()
            
        endforeach()
    endwhile()
endfunction(target_add_third_party_from_config)
