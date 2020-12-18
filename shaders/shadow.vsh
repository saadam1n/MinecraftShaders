#version 120

varying vec2 texcoords;
varying vec4 color;

#include "util/commonfuncs.glsl"

void main(){
    gl_Position = ftransform();
    gl_Position.xyz = DistortShadow(gl_Position.xyz);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_FrontColor = gl_Color;
}