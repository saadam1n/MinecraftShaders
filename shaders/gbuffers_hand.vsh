#version 120

#define GBUFFERS_HAND
#define VERTEX

#include "lib/Utility/Attributes.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Texture/NormalMap.glsl"

flat varying float fMasks;
varying mat3 TBN;

void main(){
    gl_Position = TransformVertex(mc_Entity, mc_midTexCoord);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
    fMasks = CompressMaskStruct(ConstructMaskStruct(mc_Entity.x));
    TBN = CreateTBN(); 
}