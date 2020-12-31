#ifndef SHADING_LIGHT_MAP_GLSL
#define SHADING_LIGHT_MAP_GLSL

#include "Structures.glsl"
#include "../Utility/Functions.glsl"

// Taken from KUDA 6.5.56
const vec3 TorchEmitColor = vec3(1.0, 0.57, 0.3);

// See GetLightMapTorchContinuum in /lib/Misc/UnusedCode.glsl"
// A more appoximate but faster version
// k\left(x^{p}\right)+o
// k=3.9
// p=5.06
// o=0.02435
// or
/* Desmos
k\left(\frac{s^{p}-0.5s+o}{n}\right)^{f}
s=\ x+0.062
p=1.36
o\ =\ 0.0082
n=0.563
f=1.2
k=0.5
*/
float GetLightMapTorchApprox(in float lightmap) {
    const float K = 2.0f;
    const float P = 5.06f;
    const float Offset = 0.0f;//0.02435f; // I removed the offset because it causes weird effects in low light conditions
    return K * pow(lightmap, P) + Offset;
}

float GetLightMapSky(in float sky){
    const float NonNegative = 0.062f + 0.01f; // last term is bias
    const float Power = 1.36f;
    const float Offset = 0.0082f;
    const float NormalizationFactor = 0.563f;
    const float FractionalPower = 1.2f;
    const float ScalingFactor = 0.5f;
    sky += NonNegative;
    sky = pow(sky, Power) - 0.5f * sky + Offset;
    sky /= NormalizationFactor;
    sky = pow(sky, FractionalPower);
    // why does vscode give a green blue highlight to "Fract" (case senstitive)?
    return saturate(sky * ScalingFactor);
}

// Put this in the fragment shader if the transformation curve is not straight, if not then it goes in vertex shader
void AdjustLightMap(inout SurfaceStruct surface){
    surface.Torch = GetLightMapTorchApprox(surface.Torch);
    surface.Sky = GetLightMapSky(surface.Sky);
}

void ComputeLightmap(in SurfaceStruct Surface, inout ShadingStruct Shading){
    Shading.Torch = Surface.Torch * TorchEmitColor * mix(1.0f - Surface.Sky, 1.0f, rainStrength);
    Shading.Sky = Surface.Sky * vec3(0.1f, 0.175f, 0.225f) * 1.3f;
}


#endif