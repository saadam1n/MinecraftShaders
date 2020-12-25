#version 120

varying vec2 texcoords;
varying vec4 color;

#include "lib/commonfuncs.glsl"

void main() {
    gl_FragData[0] = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
}