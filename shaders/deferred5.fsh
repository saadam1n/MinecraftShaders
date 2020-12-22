#version 120

#include "util/uniforms.glsl"

#define OPTICAL_DEPTH_FOG // Use tranmittance to fade out the background

void main(){
    vec4 BackgroundColor = texture2D(colortex7, gl_TexCoord[0].st);
    vec4 FogColor = texture2D(colortex0, gl_TexCoord[0].st);
    #ifdef OPTICAL_DEPTH_FOG
    vec3 OpticalDepth = texture2D(colortex1, gl_TexCoord[0].st).rgb;
    BackgroundColor.rgb *= exp(-OpticalDepth);
    #endif
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = BackgroundColor + FogColor;
}