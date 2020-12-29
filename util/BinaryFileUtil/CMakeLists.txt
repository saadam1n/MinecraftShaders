file(GLOB_RECURSE BinaryFileUtilSRC "*.*")

add_library(BinaryFileUtil STATIC ${BinaryFileUtilSRC})
target_include_directories(BinaryFileUtil INTERFACE "${MinecraftShadersUtil_SOURCE_DIR}/BinaryFileUtil")