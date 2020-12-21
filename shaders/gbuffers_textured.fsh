#version 120

varying vec3 normal;

#include "util/commonfuncs.glsl"

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    /* DRAWBUFFERS:0125 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(normal * 0.5f + 0.5f, 0.0f);
    gl_FragData[2] = vec4(gl_TexCoord[1].st, 0.0f, 1.0f);
    gl_FragData[3] = vec4(1.0f, 0.0f, 0.0f, 1.0f);
}