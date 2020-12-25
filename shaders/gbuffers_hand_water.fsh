#version 120

#include "lib/commonfuncs.glsl"

varying vec3 Normal;
flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;
flat varying float fMasks;

void main () {
    SurfaceStruct Surface;
    ShadingStruct Shading = CreateShadingStruct();
    MaskStruct Masks = DecompressMaskStruct(fMasks);
    CreateSurfaceStructForward(GetScreenCoords(gl_FragCoord), Normal, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading, Masks, LightDirection, CurrentSunColor); 
    ComputeColor(Surface, Shading);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = Shading.Color;
}