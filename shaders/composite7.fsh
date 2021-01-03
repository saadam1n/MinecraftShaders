#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Effect/DepthOfField.glsl"
#include "lib/Effect/BloomTile.glsl"
#include "lib/Transform/Convert.glsl"

void main(){
    vec3 BaseColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    vec3 BloomColor = CollectBloomTiles();
    BaseColor += BloomColor;
    float CoC = texture2D(colortex2, gl_TexCoord[0].st).r;
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(BaseColor, CoC);
    gl_FragData[1] = vec4(BaseColor, CoC);
}