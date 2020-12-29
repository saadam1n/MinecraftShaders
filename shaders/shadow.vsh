#version 120

#define SHADOW_PASS
#define WAVING_PLANTS

#include "lib/Utility/Attributes.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Transform/Transform.glsl"

varying vec3 Normal;

void main(){
    gl_Position = TransformVertex(mc_Entity, mc_midTexCoord);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_FrontColor = gl_Color;
    Normal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal;
}