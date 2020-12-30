#ifndef SHADING_INDIRECT_LIGHTING_GLSL
#define SHADING_INDIRECT_LIGHTING_GLSL 1

#include "Constructor.glsl"
#include "../Effect/ScreenSpaceAmbientOcclusion.glsl"

void ComputeAmbientOcclusion(inout SurfaceStruct surface, inout ShadingStruct shading){
    float SSAO = ComputeSSAO(surface);
    shading.AmbientOcclusion = SSAO; 
}

#endif