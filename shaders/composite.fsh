#version 120

#include "lib/Internal/OptifineSettings.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/Functions.glsl"
#include "lib/Effect/DepthOfField.glsl"
#include "lib/Effect/Tonemapping.glsl"
#include "lib/Transform/Convert.glsl"
#include "lib/Utility/Packing.glsl"
#include "lib/Effect/ScreenSpaceAmbientOcclusion.glsl"

const bool shadowHardwareFiltering = false;

#ifndef SSAO_ENABLED
const float ambientOcclusionLevel = 1.0f;
#endif

void main(){
    MaskStruct Masks = DecompressMaskStruct(texture2D(colortex1, gl_TexCoord[0].st).a);

    vec3 BaseColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    float PixelDistance = (LinearizeDepth(texture2D(depthtex0, gl_TexCoord[0].st).r) * (far - near)) + near;
    
    vec3 BloomColor = vec3(0.0f);
    float Brightness = Grayscale(BaseColor);
    if(((!Masks.Sky && Masks.LightSource) || Masks.Sun) && Brightness > 0.2f){
        BloomColor = BaseColor;
        if(!Masks.Sun){
            BloomColor = pow(BaseColor, vec3(2.0f));
            //float NewBrightness =  Grayscale(BloomColor);
            //BloomColor = BloomColor * NewBrightness / Brightness;
        }
        BloomColor = BloomColor * 2.6f;
        BloomColor = max(BloomColor, vec3(0.0f));
    }

    float CircleOfConfusion;
    if(Masks.Hand){
        CircleOfConfusion = 0.0f;
    } else {
        CircleOfConfusion = ComputeCircleOfConfusion(CenterDistance, PixelDistance);
    } 

    /* DRAWBUFFERS:02 */
    gl_FragData[0] = vec4(BloomColor, 1.0f);
    gl_FragData[1] = vec4(CircleOfConfusion, 0.0f, 0.0f, 1.0f);
}