# find Git and if available set GIT_HASH variable
find_package(Git QUIET)

# in case Git is not available, we default to "unknown"
set(GIT_COMMIT_COUNT 11110)
set(GIT_BRANCH D)
set(GIT_COMMIT develop)

if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%h
        OUTPUT_VARIABLE GIT_COMMIT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    
    execute_process(
        COMMAND ${GIT_EXECUTABLE} symbolic-ref --short -q HEAD
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    string(SUBSTRING ${GIT_BRANCH} 0 1 GIT_BRANCH)
    
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-list HEAD --count
        OUTPUT_VARIABLE GIT_COMMIT_COUNT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
endif()

set(GIT_VERSION "${GIT_COMMIT_COUNT}-${GIT_BRANCH}-${GIT_COMMIT}")
file(WRITE ${PROJECT_BINARY_DIR}/git_version
    "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${GIT_VERSION}"
)