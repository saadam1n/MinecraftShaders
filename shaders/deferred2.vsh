#version 120

#include "util/commonfuncs.glsl"


flat varying vec3 EyePosWorld;
flat varying vec3 EyePosShadow;
flat varying vec3 LightDirection;
flat varying vec3 LightColor;

void main(){
    gl_Position = ftransform();
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    EyePosShadow = GetEyePositionShadow();
    EyePosWorld = GetEyePositionWorld();
    LightDirection = GetLightDirection();
    LightColor = ComputeSunColor(LightDirection, LightDirection) + ComputeAtmosphereColor(LightDirection, LightDirection);
}