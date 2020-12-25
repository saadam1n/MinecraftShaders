#version 120

#define SHADOW_PASS
#define WAVING_PLANTS

#include "lib/Utility/Attributes.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/commonfuncs.glsl"

void main(){
    gl_Position = TransformVertex(mc_Entity, mc_midTexCoord);
    gl_Position.xyz = DistortShadow(gl_Position.xyz);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_FrontColor = gl_Color;
}