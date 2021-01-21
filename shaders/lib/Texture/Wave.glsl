#ifndef TEXTURE_WAVE_GLSL
#define TEXTURE_WAVE_GLSL 1

#include "NormalMap.glsl"

const float freq = 2.0f;

float sin_unorm(in float x){
    float sin_x = sin(x);
    return sin_x * 0.5f + 0.5f;
}

float CalculateWaves2D(in vec2 coords) {
    coords *= freq;
    float waves = 0.0f;
    waves += sin_unorm(1.2 * coords.x + 0.8 * coords.y);
    waves += sin_unorm(cos(-coords.x) + (2.0f * coords.y));
    waves += sin_unorm(coords.x - coords.y + frameTimeCounter);
    waves += sin_unorm(sin(coords.x * 2.0f - frameTimeCounter) + cos(coords.y * 2.0f + frameTimeCounter));
    waves += sin_unorm(coords.y - (coords.x + frameTimeCounter));
    waves += sin_unorm(coords.y - frameTimeCounter);
    waves += sin_unorm(frameTimeCounter - coords.x);
    waves /= 7.0f;
    return waves;
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
        const float Offset = 0.01f;
        const float WaveHeight = 0.5f;
        const float DiffMult = WaveHeight / Offset;
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