#version 120

#include "lib/commonfuncs.glsl"

void main(){
    vec3 BloomColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    // Taken from learnopengl.com
    float Brightness = dot(BloomColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    BloomColor.rgb *= Brightness * Brightness * Brightness * Brightness;
    //BloomColor.rgb = 4.0f * pow(BloomColor.rgb, vec3(4.0f));
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(BloomColor, 1.0f);
}