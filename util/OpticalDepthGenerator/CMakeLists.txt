get_filename_component(DirectoryName ${CMAKE_CURRENT_SOURCE_DIR} NAME)
string(REPLACE " " "_" DirectoryName ${DirectoryName})
add_executable("${DirectoryName}" "${DirectoryName}.cpp")
target_link_libraries("${DirectoryName}" BinaryFileUtil)

set_target_properties("${DirectoryName}"
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${CMAKE_CURRENT_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${CMAKE_CURRENT_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${CMAKE_CURRENT_SOURCE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}"
)