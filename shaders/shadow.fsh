#version 120

#include "lib/commonfuncs.glsl"

void main() {
    gl_FragData[0] = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
}