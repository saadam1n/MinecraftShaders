#version 120

#include "lib/Internal/OptifineSettings.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/Functions.glsl"
#include "lib/Effect/DepthOfField.glsl"
#include "lib/Transform/Convert.glsl"
#include "lib/Utility/Packing.glsl"

flat varying float CenterDistance;

void main(){
    MaskStruct Masks = DecompressMaskStruct(texture2D(colortex2, gl_TexCoord[0].st).b);

    vec3 BaseColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    float PixelDistance = (LinearizeDepth(texture2D(depthtex0, gl_TexCoord[0].st).r) * (far - near)) + near;

    vec3 BloomColor = vec3(0.0f);
    if(Masks.LightSource && texture2D(depthtex0, gl_TexCoord[0].st).r != 1.0f){
        BloomColor = BaseColor * 2.0f;
        BloomColor = max(BloomColor, vec3(0.0f));
    }

    float CircleOfConfusion = ComputeCircleOfConfusion(CenterDistance, PixelDistance);

    /* DRAWBUFFERS:02 */
    gl_FragData[0] = vec4(BloomColor, 1.0f);
    gl_FragData[1] = vec4(CircleOfConfusion, 0.0f, 0.0f, 1.0f);
}