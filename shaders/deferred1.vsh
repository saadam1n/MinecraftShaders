#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Shading/Light.glsl"

varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

void main(){
    gl_Position = ftransform();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    LightDirection = normalize(gbufferModelViewInverse * vec4(sunPosition,1.0)).xyz;
    vec4 _temp_ViewSpaceViewDir = (gbufferProjectionInverse * gl_Position);
    ViewSpaceViewDir = _temp_ViewSpaceViewDir.xyz / _temp_ViewSpaceViewDir.w;
    LightColor = GetLightColor();
}