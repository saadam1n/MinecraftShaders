#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
varying vec3 LightDir;

#include "util/commonfuncs.glsl"

void main(){
    float DeferredFlag = texture2D(colortex5, texcoords).r;
    vec4 Color;
    if(DeferredFlag == 0.0f){
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        Color.rgb = ComputeSkyColor(LightDir, Direction);
        Color.a = 1.0f;
    } else {
        Color = texture2D(colortex7, texcoords);
    }
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Color;
}