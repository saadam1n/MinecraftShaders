#version 120

#define DEFERRED1

#include "lib/Utility/Uniforms.glsl"
#include "lib/VolumeRendering/Sky.glsl"
#include "lib/VolumeRendering/Clouds.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Effect/Fog.glsl"
#include "lib/Shading/Light.glsl"
//#include "lib/Effect/Tonemapping.glsl"

varying vec3 ViewDirection;
flat varying vec3 LightColor;

void main(){
    float fMasks = texture2D(colortex1, gl_TexCoord[0].st).a;
    MaskStruct Masks = DecompressMaskStruct(fMasks);
    vec4 Color;
    if(Masks.Sky){
        Masks.Hand = false;
        Color = vec4(0.0f);
        // Doing this in the vert shading breaks mie scattering
        // And the sun color
        vec3 WorldDirection = normalize(mat3(gbufferModelViewInverse) * ViewDirection);
        vec3 OpticalDepth = vec3(0.0f);
        Color.rgb += ComputeAtmosphericScattering(SunDirection, WorldDirection, OpticalDepth);
        float SunDot = dot(WorldDirection, SunDirection);
        if(SunDot > SunSpotSize){
            vec3 TransmittedSunColor = ComputeSunColor(SunDirection, WorldDirection, OpticalDepth, SunDot);
            Color.rgb += TransmittedSunColor;
            Masks.Sun = true;
        } else {
            Masks.Sun = false;
        }
        if(isNight) Color.rgb += ComputeNightSky(ViewDirection, WorldDirection);
        Color.a = 1.0f;
        if(WorldDirection.y > 0.0f){
            Color.rgb = ComputeCloudColor(GetEyePositionWorld(), WorldDirection, SunDirection, LightColor, Color.rgb);
            
        }
        Color.rgb = Draw2DClouds(WorldDirection, isNight? MoonSkyColor * 100.0f : LightColor, Color.rgb);
    } else {
        Color = texture2D(colortex7, gl_TexCoord[0].st);
    }
    /* DRAWBUFFERS:71 */
    gl_FragData[0] = Color;
    gl_FragData[1] = vec4(0.0f, 0.0f, 0.0f, CompressMaskStruct(Masks));
}