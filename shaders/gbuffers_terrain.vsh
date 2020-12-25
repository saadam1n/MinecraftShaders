#version 120

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;

varying vec3 Normal;
varying float Masks;

#include "lib/transform/plant.glsl"
#include "lib/misc/masks.glsl"

void main(){
    gl_Position = TransformGrass(mc_Entity, mc_midTexCoord);
    Masks = CompressMaskStruct(ConstructMaskStruct(mc_Entity.x));
    Normal = gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}