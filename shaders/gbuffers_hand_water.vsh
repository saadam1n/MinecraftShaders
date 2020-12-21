#version 120

varying vec3 Normal;
varying vec3 LightDirection;

#include "util/commonfuncs.glsl"

void main() {
    gl_Position = ftransform();
    gl_FrontColor = gl_Color;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Normal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal;
    LightDirection = GetLightDirection();
}