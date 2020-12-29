#ifndef BLUR_BLOOM_TILE_GLSL
#define BLUR_BLOOM_TILE_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"

// Offsets taken from KUDA V6.5.56
const vec2 BloomTiles[] = vec2[](
    vec2(0.0f, 0.0f), 
    vec2(0.3f, 0.0f), 
    vec2(0.0f, 0.3f), 
    vec2(0.1f, 0.3f), 
    vec2(0.2f, 0.3f), 
    vec2(0.3f, 0.3f)
);

#define BLOOM_TILE_SAMPLES 3
const float BloomTileNumSamples = pow(2.0f * BLOOM_TILE_SAMPLES + 1.0f, 2.0f);
vec2 TexelSize = 1.0f / vec2(viewWidth, viewHeight);

// TODO: use a gaussian kernel
vec3 ComputeBloomTile(in float lod, vec2 offset){
    float Scale = exp2(lod);
    vec3 Accum = vec3(0.0f);
    vec2 StartCoord = Scale * (gl_TexCoord[0].st - offset);
    if(!IsInRange(StartCoord, vec2(-0.1f), vec2(1.1f))){
        return vec3(0.0f);
    }
    for(int x = -BLOOM_TILE_SAMPLES; x <= BLOOM_TILE_SAMPLES; x++){
        for(int y = -BLOOM_TILE_SAMPLES; y <= BLOOM_TILE_SAMPLES; y++){
            vec2 Offset = vec2(x, y);
            vec2 SampleCoord = gl_TexCoord[0].st + Offset * TexelSize;
            // Taken from KUDA V6.5.56
            float BloomWeight = 1.0f - length(Offset) * 0.25;
            BloomWeight = BloomWeight * BloomWeight * 14.1421356237;
            if(!IsInRange(SampleCoord, vec2(0.0f), vec2(1.0f)) && BloomWeight > 0.0f){
                continue;
            }
            vec2 BloomCoord = Scale * (SampleCoord - offset);
            Accum += texture2DLod(colortex0, BloomCoord, lod).rgb * BloomWeight;
        }
    }
    return Accum / BloomTileNumSamples;
}

vec3 ComputeBloomTiles(void){
    vec3 Accum = vec3(0.0f);
    float MaxLOD = 2.0f + BloomTiles.length();
    for(int index = 0; index < BloomTiles.length(); index++){
        float fIndex = float(index);
        float lod = 2.0f + fIndex;
        vec3 Bloom = ComputeBloomTile(lod, BloomTiles[index]) * (MaxLOD - fIndex);
        Accum += Bloom;
    }
    return Accum;
}

vec3 CollectBloomTile(in float lod, in vec2 offset){
    float Scale = exp2(-lod);
    vec2 BloomCoord = (Scale * gl_TexCoord[0].st) + offset;
    return texture2D(colortex0, BloomCoord).rgb;
}

vec3 CollectBloomTiles(void){
    vec3 Accum = vec3(0.0f);
    for(int index = 0; index < BloomTiles.length(); index++){
        float lod = 2.0f + float(index);
        Accum += CollectBloomTile(lod, BloomTiles[index]);
    }
    return Accum;
}

#endif