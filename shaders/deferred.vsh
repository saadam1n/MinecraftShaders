#version 120

varying vec2 texcoords;
flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;

#include "lib/commonfuncs.glsl"

void main(){
    gl_Position = ftransform();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    LightDirection = GetLightDirection();
    CurrentSunColor = GetLightColor();
}