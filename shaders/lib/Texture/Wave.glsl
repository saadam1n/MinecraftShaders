#ifndef TEXTURE_WAVE_GLSL
#define TEXTURE_WAVE_GLSL 1

#include "NormalMap.glsl"
#include "../Utility/TextureSampling.glsl"
#include "../Utility/Uniforms.glsl"

const float WaveNoiseTexScale =  64.0f / noiseTextureResolution;
const float freq = 0.05f * WaveNoiseTexScale;

float sin_unorm(in float x){
    float sin_x = sin(x);
    return sin_x * 0.5f + 0.5f;
}

float sin_wave(in float f, in float x){
    return sin_unorm(f * x);
}

// This is heavily based on SEUS V10.1
float CalculateWaves2D(in vec2 coords) {
    float AnimationTime = frameTimeCounter * 0.9f * WaveNoiseTexScale;
    
    coords *= freq;
    coords += 10.0f;
    float waves = 0.0f;
    coords += AnimationTime / 40.0f;
    
    float weight;
    float weights;
    
    weight = 1.0f;
    waves += BicubicTexture(noisetex, coords * vec2(1.9f, 1.2f) + vec2(0.0f, coords.x * 1.856f)).r * weight;
    weights += weight;
    coords /= 1.8f;
    coords.x -= AnimationTime / 55.0f;
    coords.y -= AnimationTime / 45.0f;
    weight = 2.24f;
    waves += BicubicTexture(noisetex, coords * vec2(1.5f, 1.3f) + vec2(0.0f,coords.x * -1.96f)).r * weight;
    weights += weight;
    coords.x += AnimationTime / 20.0f;     
    coords.y += AnimationTime / 25.0f;
    coords /= 1.3f;
    weight = 6.2f;
    waves += BicubicTexture(noisetex, coords * vec2(1.1f, 0.7f) + vec2(0.0f, coords.x * 1.265f)).r * weight;
    weights += weight;
    coords /= 2.2f;
    coords -= AnimationTime / 22.50f;
    weight = 8.34f;
    waves += BicubicTexture(noisetex, coords * vec2(1.1f, 0.7f) + vec2(0.0f, coords.x * -1.8454f)).r * weight;
    weights += weight;
    
    return waves / weights;
}

float CalculateOverlayedWaves2D(in vec2 coords){
    float waves0 = CalculateWaves2D(coords);
    float waves1 = CalculateWaves2D(-coords);
    return sqrt(waves0 * waves1);
    
}

float CaclulateWaves3D(in vec3 coords){
    return CalculateOverlayedWaves2D(coords.xy + coords.z);
}

#define WATER_WAVES

vec3 ComputeWaterWave(in vec3 pos, in mat3 TBN, in bool water){
    #ifdef WATER_WAVES
    if(water){
        const float SampleDistance = 2.0f;
        const float Offset = 0.025f * SampleDistance;
        const float WaveHeight = 0.25f;
        const float DiffMult = 35.0f * WaveHeight / SampleDistance;
        vec2 position = pos.xz;
        float Center  = CalculateOverlayedWaves2D(position);
	    float Left    = CalculateOverlayedWaves2D(position + vec2(Offset, 0.0f));
	    float Up      = CalculateOverlayedWaves2D(position + vec2(0.0f, Offset));
        vec3 WaveNormal; // normal calc taken from continuum shader
		WaveNormal.r = (Center - Left) * DiffMult;
		WaveNormal.g = (Center - Up) * DiffMult;
        WaveNormal.b = sqrt(1.0f - dot(WaveNormal.rg, WaveNormal.rg));
        return normalize(TBN * WaveNormal);
    } else {
        return ComputeNormalMap(TBN);
    }
    #else
    return ComputeNormalMap(TBN);
    #endif
}

#endif