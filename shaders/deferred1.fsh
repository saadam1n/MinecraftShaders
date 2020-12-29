#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/VolumeRendering/Sky.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Utility/Packing.glsl"

varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

void main(){
    float Masks = texture2D(colortex2, gl_TexCoord[0].st).b;
    vec4 Color;
    if(UnpackMask(Masks, SKY_BIT)){ // If DeferredFlag is 0.0f it is part of the sky
        // Init to 0
        Color = vec4(0.0f);
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        vec3 OpticalDepth = vec3(0.0f);
        Color.rgb += ComputeAtmosphericScattering(LightDirection, Direction, OpticalDepth);
        Color.rgb += ComputeSunColor(LightDirection, Direction, OpticalDepth);
        //Color.rgb = Direction * 0.5f + 0.5f;
        Color.a = 1.0f;
        /*
        if(Direction.y > 0.0f){
            Color.rgb = ComputeCloudColor(GetEyePositionWorld(), Direction, LightDirection, LightColor, Color.rgb);
        }
        */
    } else {
        Color = texture2D(colortex7, gl_TexCoord[0].st);
    }
    //Color = texture2D(colortex6, gl_TexCoord[0].st);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Color;
}