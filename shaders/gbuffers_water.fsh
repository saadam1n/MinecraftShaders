#version 120

#include "util/commonfuncs.glsl"

varying vec3 Normal;
flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;

void main () {
    SurfaceStruct Surface;
    ShadingStruct Shading;
    CreateSurfaceStructForward(GetScreenCoords(gl_FragCoord), Normal, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading, CurrentSunColor); 
    ComputeColor(Surface, Shading);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Shading.Color;
}