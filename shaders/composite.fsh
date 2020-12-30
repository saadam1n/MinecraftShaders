#version 120

#include "lib/Internal/OptifineSettings.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/Functions.glsl"
//#include "lib/Utility/ColorAdjust.glsl"

//flat varying float Exposure;

void main(){
    vec3 BloomColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    BloomColor = saturate(BloomColor);
    //BloomColor.rgb = ComputeExposureToneMap(BloomColor.rgb, Exposure);
    // Taken from learnopengl.com
    float Brightness = dot(BloomColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    BloomColor.rgb *=  pow(Brightness, 500.0f);
    //BloomColor.rgb = 4.0f * pow(BloomColor.rgb, vec3(4.0f));
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(saturate(BloomColor), 1.0f);
}