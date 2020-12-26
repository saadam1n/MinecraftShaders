#version 120

#include "lib/Utility/TextureSampling.glsl"

varying vec3 Normal;

void main() {
    gl_FragData[0] = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
}