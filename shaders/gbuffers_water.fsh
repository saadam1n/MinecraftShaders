#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Shading/Constructor.glsl"
#include "lib/Shading/Color.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Utility/Packing.glsl"

varying vec3 Normal;
flat varying vec3 CurrentSunColor;
flat varying float fMasks;

void main () {
    SurfaceStruct Surface = ConstructSurfaceStructEmpty();
    ShadingStruct Shading = ConstructShadingStructEmpty();
    MaskStruct Masks = DecompressMaskStruct(fMasks);
    if(Masks.LightSource){
        //discard;
    }
    Surface = ConstructSurfaceStructForward(GetScreenCoords(gl_FragCoord), Normal, LightDirection);
    ShadeSurfaceStruct(Surface, Shading, Masks, LightDirection, CurrentSunColor); 
    ComputeColor(Surface, Shading);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
    /* DRAWBUFFERS:71 */
    gl_FragData[0] = Shading.Color;
    gl_FragData[1].a = 0.0f;
}