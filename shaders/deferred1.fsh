#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

#include "lib/commonfuncs.glsl"
#include "lib/misc/masks.glsl"

void main(){
    float Masks = texture2D(colortex2, texcoords).b;
    vec4 Color;
    if(UnpackMask(Masks, SKY_BIT)){ // If DeferredFlag is 0.0f it is part of the sky
        // Init to 0
        Color = vec4(0.0f);
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        #ifdef PHYSICALLY_BASED_ATMOSPHERE
        vec3 OpticalDepth = vec3(0.0f);
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
    //Color.rgb = vec3(float(UnpackMask(Masks, SKY_BIT)));
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Color;
}