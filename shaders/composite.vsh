#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Transform/Convert.glsl"

flat varying float CenterDistance;

void main(){
    gl_Position = TransformVertex();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    CenterDistance = (LinearizeDepth(centerDepthSmooth) * (far - near)) + near;
}