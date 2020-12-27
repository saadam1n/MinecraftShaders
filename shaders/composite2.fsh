#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Blur/BloomTile.glsl"

#define BLOOM

void main(){
    vec4 BaseColor = texture2D(colortex7, gl_TexCoord[0].st);
    #ifdef BLOOM
    vec4 BloomColor = vec4(CollectBloomTiles(), 1.0f);
    #else
    vec4 BloomColor = vec4(0.0f);
    #endif
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = BaseColor + BloomColor;
}