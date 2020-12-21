#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;

#include "util/commonfuncs.glsl"

void main(){
    float DeferredFlag = texture2D(colortex2, texcoords).b;
    vec4 Color;
    if(DeferredFlag == 0.0f){ // If DeferredFlag is 0.0f it is part of the sky
        // Init to 0
        Color = vec4(0.0f);
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        Color.rgb = ComputeSunColor(LightDirection, Direction) + ComputeSkyColor(LightDirection, Direction);
        Color.a = 1.0f;
    } else {
        Color = texture2D(colortex7, texcoords);
    }
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Color;
}