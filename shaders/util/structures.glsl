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

#endif