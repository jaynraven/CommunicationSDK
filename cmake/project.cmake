include(function)

if(WIN32)
    add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
    add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
elseif(APPLE)
    add_compile_options(-x objective-c++)
    set(CMAKE_EXE_LINKER_FLAGS "-framework Cocoa -framework AppKit -framework CoreData -framework Foundation")
endif()

# 设置代码分类
option(USE_SOLUTION_FOLDERS "使用资源管理器文件夹" ON)
# 设置解决方案文件夹
if(USE_SOLUTION_FOLDERS)
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMakeTargets")
endif()