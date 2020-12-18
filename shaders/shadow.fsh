#version 120

varying vec2 texcoords;
varying vec4 color;

#include "util/commonfuncs.glsl"

void main() {
    gl_FragData[0] = texture2DLod(texture, gl_TexCoord[0].st, 0) * gl_Color;
}