#version 120

#define GBUFFERS_HAND_WATER
#define VERTEX

#include "lib/Utility/Attributes.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Shading/Light.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Texture/NormalMap.glsl"

varying mat3 TBN;
flat varying vec3 CurrentSunColor;
flat varying float fMasks; // TODO: stop being lazy and actually send the direct values for the masks instead of compressing and decompressing it

void main() {
    gl_Position = TransformVertex();
    gl_FrontColor = gl_Color;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    fMasks = CompressMaskStruct(ConstructMaskStruct(mc_Entity.x));
    TBN = CreateTBN();
    CurrentSunColor = GetLightColor();
}