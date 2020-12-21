#version 120

varying vec3 normal;

#include "util/commonfuncs.glsl"

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(normal * 0.5f + 0.5f, 1.0f);
}