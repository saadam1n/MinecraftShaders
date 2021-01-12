
#include "../Utility/Uniforms.glsl"
#include "../Utility/Blur.glsl"
#include "../Kernel/Bloom.glsl"

#define BLOOM_SAMPLES 15

#define COC_BLUR

void main(){
    vec3 Bloom    = vec3(0.0f);
    vec3 BloomLOD = vec3(0.0f);
    #ifdef COC_BLUR
    float CoC = 0.0f;
    #else
    float CoC = texture2D(colortex2, gl_TexCoord[0].st).r;
    #endif
    for(float Sample = -BLOOM_SAMPLES; Sample <= BLOOM_SAMPLES; Sample++){
        #ifdef BLOOM_PASS_X
        vec2 Offset = vec2(Sample, 0.0f) * TexelSize;
        #else
        vec2 Offset = vec2(0.0f, Sample) * TexelSize;
        #endif
        vec2 SampleCoord = gl_TexCoord[0].st + Offset;
        float Weight = KernelBloom[int(Sample + BLOOM_SAMPLES)];
        Bloom    += texture2D(colortex0, SampleCoord).rgb * Weight;
        BloomLOD += texture2D(colortex1, SampleCoord).rgb * Weight;
        #ifdef COC_BLUR
        CoC      += texture2D(colortex2, SampleCoord).r   * Weight;
        #endif
    }
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = vec4(Bloom          , 1.0f);
    gl_FragData[1] = vec4(BloomLOD       , 1.0f);
    gl_FragData[2] = vec4(CoC, 0.0f, 0.0f, 1.0f);
}