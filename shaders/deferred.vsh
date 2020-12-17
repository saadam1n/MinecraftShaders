#version 120

varying vec2 texcoords;
varying vec3 LightDirection;

#include "util/uniforms.glsl"

void main(){
    gl_Position = ftransform();
    texcoords = gl_MultiTexCoord0.st;
    LightDirection = normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}