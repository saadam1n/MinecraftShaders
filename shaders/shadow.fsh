#version 120

varying vec2 texcoords;
varying vec4 color;

#include "util/commonfuncs.glsl"

void main() {
    gl_FragData[0] = texture2D(texture, texcoords) * color;
}