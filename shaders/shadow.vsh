#version 120

#define SHADOW_PASS

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;

varying vec2 texcoords;
varying vec4 color;

#include "lib/commonfuncs.glsl"
#include "lib/transform/plant.glsl"

void main(){
    gl_Position = TransformGrass(mc_Entity, mc_midTexCoord);
    gl_Position.xyz = DistortShadow(gl_Position.xyz);
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_FrontColor = gl_Color;
}