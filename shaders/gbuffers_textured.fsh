#version 120

varying vec3 Normal;
varying float Masks;

#include "lib/commonfuncs.glsl"
#include "lib/misc/masks.glsl"

// Based on KUDA 6.5.56
float LumaAdjust(vec3 color) {
	return dot(color, vec3(0.3333));
}

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    //color.rgb = vec3(LumaAdjust(color.rgb));
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 0.0f);
    gl_FragData[2] = vec4(gl_TexCoord[1].st, Masks, 1.0f);
}