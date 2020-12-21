#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;

#include "util/commonfuncs.glsl"

void main(){
    float DeferredFlag = texture2D(colortex2, texcoords).b;
    vec4 Color;
    if(DeferredFlag == 0.0f){ // If DeferredFlag is 0.0f it is part of the sky
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        if(dot(Direction, LightDirection) > SunSpotSize){
            Color.rgb = ComputeSunColor(LightDirection, Direction);
        } else {
            Color.rgb = ComputeSkyColor(LightDirection, Direction);
        }
        Color.a = 1.0f;
    } else {
        Color = texture2D(colortex7, texcoords);
    }
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:74 */
    gl_FragData[0] = Color;
}