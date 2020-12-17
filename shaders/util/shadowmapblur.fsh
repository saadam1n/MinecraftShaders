// Maybe move this file to a "lib" folder?
#include "commonfuncs.glsl"

varying vec2 texcoords;

const float Kernel[] = float[](
    0.023792, 0.094907, 0.150342, 0.094907, 0.023792
);

void main() {
    vec2 ShadowCoord = DistortShadowCoordsInverse(texcoords * 2.0f - 1.0f) * 0.5f + 0.5f;
    vec4 output = vec4(0.0f);
    for(int sample = -ShadowMapBlurSamples; sample < ShadowMapBlurSamples; sample++){
        vec2 offset = 
        #if SHADOW_MAP_BLUR_PASS_X
        vec2(sample, 0.0f)
        #elif SHADOW_MAP_BLUR_PASS_Y
        vec2(0.0f, sample)
        #endif
        ;
        vec2 SampleCoord = DistortShadowCoords((ShadowCoord + offset / shadowMapResolution) * 2.0f - 1.0f) * 0.5f + 0.5f;
        output += texture2D(colortex6, SampleCoord) * Kernel[sample];
    }
    //output /= float(ShadowMapBlurTotalSamples);
    output *= 5;
    /* DRAWBUFFERS:6 */
    gl_FragData[0] = output;
}