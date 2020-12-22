#ifndef VOLUMETRIC_LIGHTING_BLUR_GLSL 
#define VOLUMETRIC_LIGHTING_BLUR_GLSL 1

#include "commonfuncs.glsl"

void main() {
    vec3 Accum = vec3(0.0f);
    for(float sample = -VOLUMETRIC_LIGHTING_BLUR_SAMPLES; sample <= VOLUMETRIC_LIGHTING_BLUR_SAMPLES; sample++){
        #ifdef VOLUMETRIC_LIGHTING_BLUR_X
        vec2 Offset = vec2(sample / viewWidth, 0.0f);
        #else
        vec2 Offset = vec2(0.0f, sample / viewHeight);
        #endif
        vec2 Sample = gl_TexCoord[0].st + Offset;
        Accum += texture2D(colortex0, Sample).rgb * Guassian(VolumetricLightingStandardDeviation, sample);
    }
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Accum, 1.0f);
}

#endif