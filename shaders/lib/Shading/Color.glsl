#ifndef SHADING_COLOR_GLSL
#define SHADING_COLOR_GLSL 1

#include "Structures.glsl"
#include "Shadow.glsl"
#include "Light.glsl"
#include "LightMap.glsl"
#include "IndirectLighting.glsl"
#include "Fog.glsl"
#include "Specular.glsl"
#include "../VolumeRendering/VolumetricLighting.glsl"

vec3 SunLightCol;

void ShadeSurfaceStruct(in SurfaceStruct Surface, inout ShadingStruct Shading, in MaskStruct masks, in vec3 sundir, in vec3 suncol){
    Shading.Sun = CalculateSunShading(Surface, suncol, masks);
    ComputeLightmap(Surface, Shading);
    //ComputeVolumetricLighting(Surface, Shading, sundir, suncol);
    #ifdef VL_APPROX_STEP_LENGTH
    Shading.Volumetric = ComputeVolumetricLightingApprox(Surface.Player, Surface.View, suncol, Shading.OpticalDepth);
    #else
    Shading.Volumetric = ComputeVolumetricLightingApprox(Surface.Player, Surface.View, suncol);
    #endif
    SunLightCol = suncol;
}

const float AmbientLighting = 0.1f;

void ComputeColor(in SurfaceStruct Surface, inout ShadingStruct Shading){
    ComputeAmbientOcclusion(Surface, Shading);
    vec3 Lighting = max(Shading.Sun, vec3(0.0f)) + Shading.Torch + Shading.Sky + mix(AmbientLighting, 0.1f * AmbientLighting, 1.0f - Surface.Sky);
    Shading.Color = vec4(Shading.Volumetric, 0.0f) + Surface.Diffuse * vec4(Lighting, 1.0f) * vec4(vec3(Shading.AmbientOcclusion), 1.0f);
    if(Surface.SpecularStrength > 0.0f){
        Shading.Color.rgb = ComputeSkyReflection(Shading.Color.rgb, Surface.SpecularStrength, Shading.Sun, SunLightCol * 20.0f, normalize(mat3(gbufferModelViewInverse) * Surface.View),normalize(Surface.Normal));
    }
    //Shading.Sun * ComputeSpecular(Surface.Shininess, Surface.SpecularStrength, Surface.Normal, normalize(-gbufferModelView[3].xyz - Surface.Player), LightDirection);
    ComputeFog(Surface, Shading);
    //Shading.Color.rgb = Shading.Color.rgb * exp(-Shading.OpticalDepth);
    //Shading.Color.rgb = vec3(Shading.AmbientOcclusion);
}

#endif