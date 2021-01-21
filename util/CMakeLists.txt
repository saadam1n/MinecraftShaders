cmake_minimum_required(VERSION 2.8)

project(MinecraftShadersUtil)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

add_subdirectory(BinaryFileUtil)
add_subdirectory(OpticalDepthGenerator)
add_subdirectory(BloomKernel)
add_subdirectory(KernelGen)