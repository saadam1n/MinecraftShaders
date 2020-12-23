#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

#include "util/commonfuncs.glsl"

void main(){
    float DeferredFlag = texture2D(colortex2, texcoords).b;
    vec4 Color;
    if(DeferredFlag == 0.0f){ // If DeferredFlag is 0.0f it is part of the sky
        // Init to 0
        Color = vec4(0.0f);
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        #ifdef PHYSICALLY_BASED_ATMOSPHERE
        vec3 OpticalDepth;
        Color.rgb += ComputeAtmosphericScattering(LightDirection, Direction, OpticalDepth);
        Color.rgb += ComputeSunColor(LightDirection, Direction, OpticalDepth);
        #else
        vec3 Absorption;
        Color.rgb += ComputeInaccurateAtmosphere(LightDirection, Direction, Absorption);
        Color.rgb += ComputeInaccurateSun(LightDirection, Direction, Absorption);
        #endif
        //Color.rgb = Direction * 0.5f + 0.5f;
        Color.a = 1.0f;
        /*
        if(Direction.y > 0.0f){
            Color.rgb = ComputeCloudColor(GetEyePositionWorld(), Direction, LightDirection, LightColor, Color.rgb);
        }
        */
    } else {
        Color = texture2D(colortex7, texcoords);
    }
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Color;
}