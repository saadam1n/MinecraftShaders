#version 120

#define GBUFFERS_WEATHER
#define VERTEX

#include "lib/Utility/Attributes.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Misc/Masks.glsl"

varying vec3 Normal;
flat varying float Masks;

void main(){
    gl_Position = TransformVertex();
    Masks = CompressMaskStruct(ConstructMaskStruct(mc_Entity.x));
    Normal = gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st * WEATHER_DENSITY;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}