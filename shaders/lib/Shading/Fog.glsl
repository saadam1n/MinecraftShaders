#ifndef SHADING_FOG_GLSL
#define SHADING_FOG_GLSL 1

#include "../Effect/Fog.glsl"
#include "Structures.glsl"

void ComputeFog(inout SurfaceStruct surface, inout ShadingStruct shading){
    shading.Color.rgb = ComputeFog(surface.World, surface.View, shading.Color.rgb, surface.Sky);
}

#endif