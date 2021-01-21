#version 120

#define GBUFFERS_HAND

#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/TextureSampling.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Texture/NormalMap.glsl"

flat varying float fMasks;
varying mat3 TBN;

void main(){ 
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    MaskStruct Masks = DecompressMaskStruct(fMasks);
    /* DRAWBUFFERS:012 */
    gl_FragData[0].rgba = color;
    gl_FragData[1].rgba = vec4(ComputeNormalMap(TBN) * 0.5f + 0.5f, fMasks);
    gl_FragData[2].rgb  = vec3(gl_TexCoord[1].st, 0.0f);
}