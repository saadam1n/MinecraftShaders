#version 120

attribute vec3 mc_Entity;

varying vec3 Normal;
varying float Masks;

#include "lib/Utility/Uniforms.glsl"
#include "lib/Misc/Masks.glsl"

void main(){
    gl_Position = ftransform();
    Masks = CompressMaskStruct(ConstructMaskStruct(mc_Entity.x));
    Normal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}