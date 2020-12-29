#version 120

varying vec3 Normal;
flat varying float fMasks;

#include "lib/Utility/TextureSampling.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Utility/ColorAdjust.glsl"

#define LUMA_ADJUSTED_RAIN

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    #ifdef LUMA_ADJUSTED_RAIN
    color.rgb = vec3(Luma(color.rgb));
    #endif
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5, 0.0f);
    gl_FragData[2] = vec4(gl_TexCoord[1].st, fMasks, 1.0f);
}