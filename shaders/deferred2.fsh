#version 120

#include "util/commonfuncs.glsl"

flat varying vec3 EyePosWorld;
flat varying vec3 EyePosShadow;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

void main() {
    SurfaceStruct Surface;
    ShadingStruct Shading;

    Surface.Screen = vec3(gl_TexCoord[0].st, texture2D(depthtex0, gl_TexCoord[0].st).r);
    Surface.Clip = Surface.Screen * 2.0f - 1.0f;
    vec4 UnDivW = gbufferProjectionInverse * vec4(Surface.Clip, 1.0f);
    Surface.View = UnDivW.xyz / UnDivW.w;
    Surface.Player = (gbufferModelViewInverse * vec4(Surface.View, 1.0f)).xyz;
    Surface.World = Surface.Player + cameraPosition;
    UnDivW = shadowProjection * shadowModelView * vec4(Surface.Player, 1.0f);
    Surface.ShadowClip = UnDivW.xyz;// / UnDivW.w;

    ComputeVolumetricLighting(Surface, Shading, LightDirection, LightColor, EyePosWorld, EyePosShadow);
    vec3 VolumetricFogColor = Shading.Volumetric;
    vec3 OpticalDepth = Shading.OpticalDepth;

    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(VolumetricFogColor, 1.0f);
    gl_FragData[1] = vec4(OpticalDepth, 1.0f);
}