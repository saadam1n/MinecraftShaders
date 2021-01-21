#include "../Utility/Uniforms.glsl"
#include "../Utility/Blur.glsl"
#include "../Kernel/Bloom.glsl" // use same kernel for bloom since I'm lazy

#define BLUR_SAMPLES 15
const float Kernel[] = float[] (
0.02066193419674808643f,
        0.02213548368572298974f,
        0.02360896288755569977f,
        0.02506886005762001823f,
        0.02650098741677663766f,
        0.02789069456869578204f,
        0.02922310619819265889f,
        0.03048339044031582110f,
        0.03165701446995517615f,
        0.03273003076220291907f,
        0.03368935568502623434f,
        0.03452302253297920287f,
        0.03522043200501863425f,
        0.03577258990283950502f,
        0.03617227837591226874f,
        0.03641423483420850454f,
        0.03649524396045973618f,
        0.03641423483420850454f,
        0.03617227837591226874f,
        0.03577258990283950502f,
        0.03522043200501863425f,
        0.03452302253297920287f,
        0.03368935568502623434f,
        0.03273003076220291907f,
        0.03165701446995517615f,
        0.03048339044031582110f,
        0.02922310619819265889f,
        0.02789069456869578204f,
        0.02650098741677663766f,
        0.02506886005762001823f,
        0.02360896288755569977f,
        0.02213548368572298974f,
        0.02066193419674808643f
);

void main() {
    vec3 BlurAccum = vec3(0.0f);
    for(float sample = -BLUR_SAMPLES; sample <= BLUR_SAMPLES; sample++) {
        #ifdef LENS_FLARE_BLUR_X
        vec2 Coord = vec2(sample / viewWidth, 0.0f);
        #else
        vec2 Coord = vec2(0.0f, sample / viewHeight);
        #endif
        BlurAccum += texture2D(colortex3, Coord + gl_TexCoord[0].st).rgb * Kernel[int(sample + BLUR_SAMPLES)];
    }
    /* DRAWBUFFERS:3 */
    gl_FragData[0].rgb = BlurAccum;
}