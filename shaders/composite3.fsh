#version 120

#include "util/uniforms.glsl"

void main(){
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = texture2D(colortex7, gl_TexCoord[0].st) + texture2D(colortex0, gl_TexCoord[0].st);
}