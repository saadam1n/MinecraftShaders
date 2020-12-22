#version 120

#include "util/commonfuncs.glsl"

varying vec2 texcoords;
flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;

#include "util/uniforms.glsl"

void main(){
    SurfaceStruct Surface;
    ShadingStruct Shading;
    CreateSurfaceStructDeferred(gl_TexCoord[0].st, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading, LightDirection, CurrentSunColor); 
    ComputeColor(Surface, Shading);
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Shading.Color;
}