#version 120

#define DEFERRED_SHADING

#include "lib/Shading/Color.glsl"
#include "lib/Utility/Packing.glsl"

flat varying vec3 CurrentSunColor;

void main(){
    float Flags = texture2D(colortex1, gl_TexCoord[0].st).a;
    bool DeferredFragment = !UnpackMask(Flags, SKY_BIT);
    if(DeferredFragment){
        SurfaceStruct Surface = ConstructSurfaceStructEmpty();
        ShadingStruct Shading = ConstructShadingStructEmpty();
        // TODO: avoid recomputation of the sky flag
        MaskStruct Masks = DecompressMaskStruct(Flags);
        Surface = ConstructSurfaceStructDeferred(gl_TexCoord[0].st, LightDirection, Masks);
        ShadeSurfaceStruct(Surface, Shading, Masks, LightDirection, CurrentSunColor); 
        ComputeColor(Surface, Shading);
        /* DRAWBUFFERS:7 */
        gl_FragData[0] = Shading.Color;
    } else {
        discard;
    }

}