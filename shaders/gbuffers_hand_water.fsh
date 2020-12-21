#version 120

#include "util/commonfuncs.glsl"

varying vec3 Normal;
varying vec3 LightDirection;

void main () {
    SurfaceStruct Surface;
    ShadingStruct Shading;
    CreateSurfaceStructForward(GetScreenCoords(gl_FragCoord), Normal, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading); 
    ComputeColor(Surface, Shading);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Shading.Color;
}