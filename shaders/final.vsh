#version 120

#include "lib/commonfuncs.glsl"

void main(){
    gl_Position = ftransform();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = (gl_MultiTexCoord0.st * vec2(viewWidth, viewHeight) / noiseTextureResolution) + GetRandomNumber().xy;
}