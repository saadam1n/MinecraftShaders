#version 120

#include "util/commonfuncs.glsl"

varying vec2 texcoords;
varying vec3 LightDirection;

#include "util/uniforms.glsl"

void main(){
    SurfaceStruct Surface;
    ShadingStruct Shading;
    CreateSurfaceStructDeferred(gl_TexCoord[0].st, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading); 
    ComputeColor(Surface, Shading);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Shading.Color;
}