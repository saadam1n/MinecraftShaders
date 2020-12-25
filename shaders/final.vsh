#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Random/Noise1D.glsl"

void main(){
    gl_Position = TransformVertex();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = (gl_MultiTexCoord0.st * vec2(viewWidth, viewHeight) / noiseTextureResolution) + GetRandomNumber().xy;
}