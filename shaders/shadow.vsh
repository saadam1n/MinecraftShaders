#version 120

varying vec2 texcoords;
varying vec4 color;

#include "util/commonfuncs.glsl"

void main(){
    gl_Position = ftransform();
    gl_Position.xyz = DistortShadow(gl_Position.xyz);
    texcoords = gl_MultiTexCoord0.st;
    color = gl_Color;
}