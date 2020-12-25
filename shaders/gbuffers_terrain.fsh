#version 120

varying vec3 Normal;
flat varying float Masks;

#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/TextureSampling.glsl"

void main(){
    vec4 color = SampleTextureAtlas(gl_TexCoord[0].st) * gl_Color;
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 0.0f);
    gl_FragData[2] = vec4(gl_TexCoord[1].st, Masks, 1.0f);
}