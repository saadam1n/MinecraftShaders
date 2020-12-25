#version 120

#define DEFERRED_SHADING

#include "lib/commonfuncs.glsl"
#include "lib/misc/masks.glsl"

varying vec2 texcoords;
flat varying vec3 LightDirection;
flat varying vec3 CurrentSunColor;

#include "lib/uniforms.glsl"

void main(){
    float Flags = texture2D(colortex2, gl_TexCoord[0].st).b;
    bool DeferredFragment = !UnpackMask(Flags, SKY_BIT);
    if(DeferredFragment){
        SurfaceStruct Surface;
        ShadingStruct Shading = CreateShadingStruct();
        CreateSurfaceStructDeferred(gl_TexCoord[0].st, LightDirection, Surface);
        ShadeSurfaceStruct(Surface, Shading, LightDirection, CurrentSunColor); 
        ComputeColor(Surface, Shading);
        /* DRAWBUFFERS:7 */
        gl_FragData[0] = Shading.Color;
    } else {
        discard;
    }
}