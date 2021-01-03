#version 120

#include "lib/Transform/Transform.glsl"

void main(){
    gl_Position = TransformVertex();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
}