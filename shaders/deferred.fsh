#version 120

#include "util/commonfuncs.glsl"

varying vec2 texcoords;
varying vec3 LightDirection;

#include "util/uniforms.glsl"

void main(){
    vec4 color = texture2D(colortex0, texcoords);
    vec3 normal = texture2D(colortex1, texcoords).rgb * 2.0f - 1.0f;
    vec2 lmcoords = texture2D(colortex2, texcoords).st;
    float NdotL = dotunorm(normal, LightDirection);
    vec3 ShadowColor = ComputeShadow(NdotL, texcoords);
    vec3 SunLighting = NdotL * ShadowColor;
    vec3 LightmapLighting = ComputeLightmap(lmcoords);
    color.rgb *= SunLighting + LightmapLighting;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = color;
}