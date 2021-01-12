#ifndef EFFECT_SCREEN_SPACE_AMBIENT_OCCLUSION_GLSL
#define EFFECT_SCREEN_SPACE_AMBIENT_OCCLUSION_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Shading/Structures.glsl"

#define SSAO_SAMPLES 64.0f

const float SSAOLength = 1.0f; 

#define SSAO_ENABLED

float ComputeSSAO(in SurfaceStruct surface){
    // SSAO isn't really working right now, so lets just return 1.0f
    return 1.0f;
    // Here is the broken implementation
    float CurrentDepth = texture2D(depthtex0, surface.Screen.xy).r;
    vec3 Tangent = cross(surface.ViewNormal, normalize(texture2D(noisetex, surface.Screen.xy).rgb));
    vec3 Bitangent = cross(surface.ViewNormal, Tangent);
    mat3 TBN = mat3(Tangent, Bitangent, surface.ViewNormal);
    float AmbientVisiblity = 0.0f;
    for(int sample = 0; sample < SSAO_SAMPLES; sample++){
        vec3 RandomDirection = vec3 (
            texture2D(noisetex, vec2(0.1f + (sample) / 64.0f)).rgb // Taken from contiuum 1.3
        );
        RandomDirection.xz = RandomDirection.xz * 2.0f - 1.0f;
        RandomDirection.y -= 1.0f;
        RandomDirection = TBN * SSAOLength * normalize(RandomDirection);
        vec3 SampleLocation = surface.View + RandomDirection;
        vec4 NDC = gbufferProjection * vec4(SampleLocation, 1.0f);
        vec2 SampleCoords = saturate((NDC.xy / NDC.w) * 0.5f + 0.5f);
        float SampleDepth = texture2D(depthtex0, SampleCoords).r;
        AmbientVisiblity += step(CurrentDepth, SampleDepth);
    }
    AmbientVisiblity /= SSAO_SAMPLES;
    return AmbientVisiblity;
}

#endif