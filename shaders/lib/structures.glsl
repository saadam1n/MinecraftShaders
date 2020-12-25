#ifndef STRUCTURES_GLSL
#define STRUCTURES_GLSL 1

// Use the same names that SEUS V10.1 did
struct SurfaceStruct {
    vec4 Diffuse;
    vec3 Normal;

    vec3 Screen;
    vec3 Clip;
    vec3 View;
    vec3 Player;
    vec3 World;
    vec3 ShadowClip;
    float Distortion;
    vec3 ShadowScreen;

    float Torch;
    float Sky;

    float NdotL;

};

struct ShadingStruct {
    vec4 Color;

    vec3 Sun;
    vec3 Torch;
    vec3 Sky;
    vec3 Volumetric;
    vec3 OpticalDepth;
};

SurfaceStruct CreateSurfaceStruct(void){
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

ShadingStruct CreateShadingStruct(void){
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