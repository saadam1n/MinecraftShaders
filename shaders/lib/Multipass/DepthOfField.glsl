#ifndef MULTIPASS_DEPTH_OF_FIELD_GLSL
#define MULTIPASS_DEPTH_OF_FIELD_GLSL 1

#include "../Utility/Uniforms.glsl"

#define DOF_KERNEL_SIZE 6.0f

void main() {
    vec4 Accum = vec4(0.0f);
    float CoC = texture2D(colortex0, gl_TexCoord[0].st).a;
    for(float sample = -DOF_KERNEL_SIZE; sample <= DOF_KERNEL_SIZE; sample++){
        #ifdef DOF_BOKEH_X
        vec2 Offset = vec2(sample / viewWidth, 0.0f);
        #else
        vec2 Offset = vec2(0.0f, sample / viewHeight);
        #endif
        Offset *= CoC;
        vec2 Sample = gl_TexCoord[0].st + Offset;
        Accum += texture2D(colortex0, Sample);
    }
    Accum /= (2.0f * DOF_KERNEL_SIZE + 1.0f);
    Accum.a = CoC;
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = Accum;
}

#endif