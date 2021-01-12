#version 120

#define DEFERRED1

#include "lib/Utility/Uniforms.glsl"
#include "lib/Shading/Light.glsl"

varying vec3 ViewDirection;
flat varying vec3 LightColor;

void main(){
    gl_Position = ftransform();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    vec4 _temp_ViewSpaceViewDir = (gbufferProjectionInverse * gl_Position);
    vec3 ViewSpaceViewDir = _temp_ViewSpaceViewDir.xyz / _temp_ViewSpaceViewDir.w;
    ViewDirection = ViewSpaceViewDir;
    LightColor = GetLightColor();
}