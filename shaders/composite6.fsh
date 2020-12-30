#version 120

#include "lib/Utility/Uniforms.glsl"

void main() {
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = min(texture2D(colortex0, gl_TexCoord[0].st), texture2D(colortex1, gl_TexCoord[0].st));
}