#ifndef TRANSFORM_CONVERT_GLSL
#define TRANSFORM_CONVERT_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "Distort.glsl"

vec3 GetViewSpace(vec2 texcoord = gl_TexCoord[0].st, in float depth){
    vec4 ndc = vec4(texcoord * 2.0f - 1.0f, depth * 2.0f - 1.0f, 1.0f);
    ndc = gbufferProjectionInverse * ndc;
    return ndc.xyz / ndc.w;
}

vec3 GetViewSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    return GetViewSpace(texcoord, texture2D(depthsampler, texcoord).r);
}

vec3 GetPlayerSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    return (gbufferModelViewInverse * vec4(GetViewSpace(texcoord, depthsampler), 1.0f)).xyz;
}

vec3 GetWorldSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0) {
    return GetPlayerSpace(texcoord, depthsampler) + cameraPosition;
}

vec3 GetShadowSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    vec4 pos = vec4(GetPlayerSpace(texcoord, depthsampler), 1.0f);
    pos = shadowProjection * shadowModelView * pos;
    pos.xyz /= pos.w;
    return pos.xyz;
}

vec3 GetShadowSpaceDistorted(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    return DistortShadow(GetShadowSpace(texcoord, depthsampler));
}

vec3 GetShadowSpaceDistortedSample(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    return GetShadowSpaceDistorted(texcoord, depthsampler) * 0.5f + 0.5f;
}

vec3 GetShadowSpaceSample(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
    return GetShadowSpace(texcoord, depthsampler) * 0.5f + 0.5f;
}

// taken from https://learnopengl.com/Advanced-OpenGL/Depth-testing 
float LinearizeDepth(in float depth){
    return (2.0f * near * far) / (far + near - (2.0f * depth - 1.0f) * (far - near)); 
}

#endif