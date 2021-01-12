#version 120

#include "lib/Transform/Transform.glsl"
#include "lib/Shading/Light.glsl"

flat varying vec3 CurrentSunColor;

void main(){
    gl_Position = TransformVertex();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    CurrentSunColor = GetLightColor();
}