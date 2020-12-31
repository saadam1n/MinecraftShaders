#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/TextureSampling.glsl"
#include "lib/Utility/Packing.glsl"

varying vec3 Normal;
flat varying float fMasks;

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    /* DRAWBUFFERS:012 */
    gl_FragData[0].rgba = color;
    gl_FragData[1].rgb  = Normal * 0.5f + 0.5;
    gl_FragData[2].rgb  = vec3(gl_TexCoord[1].st, fMasks);
}