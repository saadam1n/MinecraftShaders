#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
varying vec3 LightDir;

#include "util/uniforms.glsl"

void main(){
    gl_Position = ftransform();
    texcoords = gl_MultiTexCoord0.st;
    LightDir = normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
    vec4 _temp_ViewSpaceViewDir = (gbufferProjectionInverse * gl_Position);
    ViewSpaceViewDir = _temp_ViewSpaceViewDir.xyz / _temp_ViewSpaceViewDir.w;
    gl_TexCoord[0].st = texcoords;
}