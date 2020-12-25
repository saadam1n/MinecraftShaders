#version 120

#include "lib/uniforms.glsl"

#define BLOOM

void main(){
    vec4 BaseColor = texture2D(colortex7, gl_TexCoord[0].st);
    #ifdef BLOOM
    vec4 BloomColor = texture2D(colortex0, gl_TexCoord[0].st);
    float LensDirt = texture2D(colortex1, gl_TexCoord[0].st).r;
    BloomColor.rgb *= LensDirt;
    #else
    vec4 BloomColor = vec4(0.0f);
    #endif
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = BaseColor + BloomColor;
}