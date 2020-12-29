#ifndef GAUSSIAN_BLOOM_GLSL
#define GAUSSIAN_BLOOM_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Utility/Constants.glsl"
#include "../Utility/Blur.glsl"

#define BLOOM_THRESHOLD 0.5f
#define BLOOM_SAMPLES 16.0f

const float BloomSamplesPerSide = (2.0f * BLOOM_SAMPLES + 1.0f);
const float BloomStandardDeviation = 10;

void main() {
    vec3 Accum = vec3(0.0f);
    for(float sample = -BLOOM_SAMPLES; sample <= BLOOM_SAMPLES; sample++){
        #ifdef GAUSSIAN_BLOOM_X
        vec2 Offset = vec2(sample / viewWidth, 0.0f);
        #else
        vec2 Offset = vec2(0.0f, sample / viewHeight);
        #endif
        vec2 Sample = gl_TexCoord[0].st + Offset;
        Accum += texture2D(colortex0, Sample).rgb * Guassian(BloomStandardDeviation, sample);
    }
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Accum, 1.0f);
}

#endif