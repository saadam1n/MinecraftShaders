#version 120

#include "util/commonfuncs.glsl"

varying vec2 texcoords;
varying vec3 LightDirection;

#include "util/uniforms.glsl"

void main(){
    SurfaceStruct Surface;
    ShadingStruct Shading;
    CreateSurfaceStructDeferred(texcoords, LightDirection, Surface);
    ShadeSurfaceStruct(Surface, Shading); 
    ComputeColor(Surface, Shading);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
    /* DRAWBUFFERS:7 */
    gl_FragData[0] = vec4(Shading.Color, 1.0f);
}