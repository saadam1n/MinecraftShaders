#version 120

#extension GL_EXT_gpu_shader4 : enable

#include "lib/Utility/Uniforms.glsl"
#include "lib/Transform/Transform.glsl"
#include "lib/Random/Noise1D.glsl"
#include "lib/Utility/ColorAdjust.glsl"

flat varying float inRain;
flat varying float Exposure;

void main(){
    gl_Position = TransformVertex();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = (gl_MultiTexCoord0.st * vec2(viewWidth, viewHeight) / noiseTextureResolution) + GetRandomNumber().xy;
    inRain = float(int((float(eyeBrightness.y) / 240.0f) > 0.9f) & int(rainStrength > 0.99f));
    Exposure = CalculateExposure();
}