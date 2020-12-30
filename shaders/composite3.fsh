#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Effect/DepthOfField.glsl"
#include "lib/Transform/Convert.glsl"

void main(){
    vec3 BaseColor = texture2D(colortex7, gl_TexCoord[0].st).rgb;
    float LinearDepth = LinearizeDepth(texture2D(depthtex0, gl_TexCoord[0].st).r);
    float CenterDepth = LinearizeDepth(centerDepthSmooth);
    // TODO: avoid computing far - near for each fragment, make it flat varying
    // Also avoiud computing center depth (S1)
    float CenterDist = (CenterDepth * (far - near)) + near;
    float Distance = (LinearDepth * (far - near)) + near;
    float CoC = ComputeCircleOfConfusion(CenterDist, Distance);
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(BaseColor, CoC);
    gl_FragData[1] = vec4(BaseColor, CoC);
}