#version 120

#define SHADOW_PASS
#define WAVING_PLANTS

#include "lib/Utility/Attributes.glsl"
#include "lib/Transform/Transform.glsl"

void main(){
    gl_Position = TransformVertex(mc_Entity, mc_midTexCoord);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_FrontColor = gl_Color;
}