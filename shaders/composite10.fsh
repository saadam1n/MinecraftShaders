#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Effect/LensFlare.glsl"

void main() {
    vec3 BaseColor = min(texture2D(colortex0, gl_TexCoord[0].st).rgb, texture2D(colortex1, gl_TexCoord[0].st).rgb);
    vec3 LensFlare = ComputeLensFlare();
    // Why not just vec3 FinalColor = BaseColor + LensFlare?
    // It is this way so I can quickly turn on and off the effect or base color
    vec3 FinalColor = vec3(0.0f);
    FinalColor += BaseColor;
    FinalColor += LensFlare;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = vec4(FinalColor, 1.0f);
}