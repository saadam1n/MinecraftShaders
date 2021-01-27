#ifndef SHADING_CONSTRUCTOR_GLSL
#define SHADING_CONSTRUCTOR_GLSL

#include "Structures.glsl"
#include "LightMap.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Utility/TextureSampling.glsl"
#include "../Transform/Distort.glsl"
#include "../Utility/Packing.glsl"

vec3 GetScreenCoords(in vec4 fragcoord){
    //fragcoord.xyz *= fragcoord.w;
    // Move this to vert shader if possible
    vec2 Screen = fragcoord.xy / vec2(viewWidth, viewHeight);
    return vec3(Screen, fragcoord.z);
}

const float WaterShininess = 128.0f;

SurfaceStruct ConstructSurfaceStructForward(in vec3 fragcoord, in vec3 normal, in vec3 l, in MaskStruct Masks){
    SurfaceStruct Surface;

    if(Masks.Water){
        Surface.Diffuse = vec4(0.02f, 0.1f, 0.5f, 0.75f);
        //Surface.Diffuse.rgb =  normal;
    } else {
        Surface.Diffuse = SampleTextureAtlas(gl_TexCoord[0].st);
        // If the alpha channel does not have the gamma backed into it, someone please let me knwo
        Surface.Diffuse.rgba = pow(Surface.Diffuse.rgba, vec4(2.2f));
    }

    Surface.Normal =  normal;
    Surface.ViewNormal = mat3(gbufferModelView) * normal;
    //Surface.Diffuse.rgb = Surface.Normal;

    vec2 LightMap = gl_TexCoord[1].st; 
    Surface.Torch = LightMap.x;
    Surface.Sky = LightMap.y;
    AdjustLightMap(Surface);

    if(Masks.Hand) fragcoord.z += 0.38f;

    // In a way the screen space coords contain the texcoords
    Surface.Screen = vec3(fragcoord);
    Surface.Clip = Surface.Screen * 2.0f - 1.0f;
    vec4 UnDivW = gbufferProjectionInverse * vec4(Surface.Clip, 1.0f);
    Surface.View = UnDivW.xyz / UnDivW.w;
    Surface.Player = (gbufferModelViewInverse * vec4(Surface.View, 1.0f)).xyz;
    Surface.World = Surface.Player + cameraPosition;
    UnDivW = shadowProjection * shadowModelView * vec4(Surface.Player, 1.0f);
    Surface.ShadowClip = UnDivW.xyz;// / UnDivW.w;
    Surface.Distortion = DistortionFactor(Surface.ShadowClip.xy);
    Surface.ShadowScreen = DistortShadowSample(Surface.ShadowClip);

    Surface.NdotL = dotunorm(Surface.Normal, l);

    if(Masks.Water){
        Surface.Shininess = WaterShininess;
        Surface.SpecularStrength = 1.0f;
    } else {
        Surface.Shininess = 1.0f;
        Surface.SpecularStrength = 0.0f;
    }

    return Surface;
}

SurfaceStruct ConstructSurfaceStructDeferred(in vec2 texcoords, in vec3 l, in MaskStruct Masks){
    SurfaceStruct Surface;

    Surface.Diffuse = texture2D(colortex0, texcoords);
    Surface.Diffuse.rgb = pow(Surface.Diffuse.rgb, vec3(2.2f));
    Surface.Normal = normalize(texture2D(colortex1, texcoords).rgb * 2.0f - 1.0f);
    Surface.ViewNormal = mat3(gbufferModelView) * Surface.Normal;
    //Surface.Diffuse.rgb = Surface.Normal;

    vec2 LightMap = texture2D(colortex2, texcoords).st; 
    Surface.Torch = LightMap.x;
    Surface.Sky = LightMap.y;
    AdjustLightMap(Surface);

    float Depth = texture2D(depthtex0, texcoords).r;
    if(Masks.Hand) Depth += 0.38f; // Continuum Shader's method 

    // In a way the screen space coords contain the texcoords
    Surface.Screen = vec3(texcoords, Depth);
    Surface.Clip = Surface.Screen * 2.0f - 1.0f;
    vec4 UnDivW = gbufferProjectionInverse * vec4(Surface.Clip, 1.0f);
    Surface.View = UnDivW.xyz / UnDivW.w;
    Surface.Player = (gbufferModelViewInverse * vec4(Surface.View, 1.0f)).xyz;
    Surface.World = Surface.Player + cameraPosition;
    UnDivW = shadowProjection * shadowModelView * vec4(Surface.Player, 1.0f);
    Surface.ShadowClip = UnDivW.xyz;// / UnDivW.w;
    Surface.Distortion = DistortionFactor(Surface.ShadowClip.xy);
    Surface.ShadowScreen = DistortShadowSample(Surface.ShadowClip);

    Surface.NdotL = dotunorm(Surface.Normal, l);

    if(Masks.Water){
        Surface.Shininess = WaterShininess;
        Surface.SpecularStrength = 1.0f;
    } else {
        Surface.Shininess = 1.0f;
        Surface.SpecularStrength = 0.0f;
    }

    return Surface;
}

SurfaceStruct ConstructSurfaceStructEmpty(void){
    SurfaceStruct Surface;
    Surface.Diffuse = vec4(0.0f);
    Surface.Screen = vec3(0.0f);
    Surface.Clip = vec3(0.0f);
    Surface.View = vec3(0.0f);
    Surface.Player = vec3(0.0f);
    Surface.World = vec3(0.0f);
    Surface.ShadowClip = vec3(0.0f);
    Surface.ShadowScreen = vec3(0.0f);
    Surface.Distortion = 0.0f;
    Surface.Torch = 0.0f;
    Surface.Sky = 0.0f;
    Surface.NdotL = 0.0f;
    return Surface;
}

ShadingStruct ConstructShadingStructEmpty(void){
    ShadingStruct Shading;
    Shading.Color= vec4(0.0f);
    Shading.Sun = vec3(0.0f);
    Shading.Torch = vec3(0.0f);
    Shading.Sky = vec3(0.0f);
    Shading.Volumetric = vec3(0.0f);
    Shading.OpticalDepth = vec3(0.0f);
    return Shading;
}

#endif