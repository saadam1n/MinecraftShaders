#ifndef SHADING_COLOR_GLSL
#define SHADING_COLOR_GLSL 1

#include "Structures.glsl"
#include "Shadow.glsl"
#include "Light.glsl"
#include "LightMap.glsl"

void ShadeSurfaceStruct(in SurfaceStruct Surface, inout ShadingStruct Shading, in MaskStruct masks, in vec3 sundir, in vec3 suncol){
    Shading.Sun = CalculateSunShading(Surface, suncol, masks);
    ComputeLightmap(Surface, Shading);
    Shading.Volumetric *= suncol;
}

const float AmbientLighting = 0.1f;

void ComputeColor(in SurfaceStruct Surface, inout ShadingStruct Shading){
    vec3 Lighting = max(Shading.Sun, vec3(0.0f)) + Shading.Torch + Shading.Sky + mix(AmbientLighting, 0.1f * AmbientLighting, 1.0f - Surface.Sky);
    Shading.Color = Surface.Diffuse * vec4(Lighting, 1.0f);
}

#endif