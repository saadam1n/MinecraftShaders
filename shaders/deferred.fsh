#version 120

#define DEFERRED_SHADING

#include "lib/Utility/Uniforms.glsl"
#include "lib/Shading/Constructor.glsl"
#include "lib/Shading/Color.glsl"
#include "lib/Misc/Masks.glsl"
#include "lib/Utility/Packing.glsl"

flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;

void main(){
    float Flags = texture2D(colortex2, gl_TexCoord[0].st).b;
    bool DeferredFragment = !UnpackMask(Flags, SKY_BIT);
    if(DeferredFragment){
        SurfaceStruct Surface = ConstructSurfaceStructEmpty();
        ShadingStruct Shading = ConstructShadingStructEmpty();
        // TODO: avoid recomputation of the sky flag
        MaskStruct Masks = DecompressMaskStruct(Flags);
        Surface = ConstructSurfaceStructDeferred(gl_TexCoord[0].st, LightDirection);
        ShadeSurfaceStruct(Surface, Shading, Masks, LightDirection, CurrentSunColor); 
        ComputeColor(Surface, Shading);
        /* DRAWBUFFERS:7 */
        gl_FragData[0] = Shading.Color;
    } else {
        discard;
    }
}