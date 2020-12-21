#version 120

varying vec3 normal;

#include "util/commonfuncs.glsl"

void main(){
    gl_Position = ftransform();
    normal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}