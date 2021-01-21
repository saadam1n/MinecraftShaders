#version 120

#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/ColorAdjust.glsl"
#include "lib/Effect/LensFlare.glsl"


// Use same values as https://github.com/john-chapman/GfxSamples/blob/master/src/LensFlare_ScreenSpace/LensFlare_ScreenSpace.h 
const int GhostCount = 8;
const float GhostSpacing = 0.3f;
const float ChromaticAberationStrength = 0.2f;
const float GhostLOD = 0.0f;
const vec3 GhostThreshold = vec3(30.0f);

vec3 SampleChromaticAberrationColor(in vec2 Sample, in vec2 Offset){
    Offset *= ChromaticAberationStrength;
    vec3 Color;
    Color.r = texture2DLod(colortex0, Sample - Offset, GhostLOD).r;
    Color.g = texture2DLod(colortex0, Sample         , GhostLOD).g;
    Color.b = texture2DLod(colortex0, Sample + Offset, GhostLOD).b;
    Color = max(Color - GhostThreshold, vec3(0.0f));
    return Color;
}

vec3 ComputeGhosts(void) {
    vec3 GhostAccum = vec3(0.0f);
    vec2 TexCoord = 1.0f - gl_TexCoord[0].st;
    vec2 GhostVector = (0.5f - TexCoord) * GhostSpacing;
    for(int Ghost = 0; Ghost < GhostCount; Ghost++){
        vec2 Sample = fract(TexCoord + GhostVector * Ghost);
        vec2 Offset = Sample - 0.5f;
        vec3 Color = SampleChromaticAberrationColor(Sample, Offset);
        float Weight = 1.0f - smoothstep(0.0f, 0.75f, length(Sample - 0.5f));
        GhostAccum += Color * Weight;
    }
    return GhostAccum;
}

const float HaloRadius = 0.76f;
const float HaloThickness = 0.1f;

// Kappa V2.2 Halos
vec3 ComputeHalo(void){
    vec2 HaloTexCoord = 0.5f - gl_TexCoord[0].st;
    HaloTexCoord.x *= aspectRatio;
    vec2 HaloVector = normalize(-HaloTexCoord) * HaloRadius;
    HaloTexCoord += 0.5f;
    vec2 HaloSample = (HaloTexCoord + HaloVector);
    vec2 Offset = HaloSample - 0.5f;
    float Distance = distance((1.0f - gl_TexCoord[0].st - vec2(0.5, 0.0)) / vec2(aspectRatio, 1.0) + vec2(0.5, 0.0), vec2(0.5));
    float Weight = 1.0f / (1.0f + pow(abs(Distance - HaloThickness),7.0f));
    return SampleChromaticAberrationColor(HaloSample, Offset) * Weight;
}

vec2 DefaultTexCoords[3] = vec2[3] (gl_TexCoord[0].st, gl_TexCoord[0].st, gl_TexCoord[0].st);

void main(){
    vec3 LensFlare = ComputeGhosts() * 0.12f;
    vec3 Halo = ComputeHalo();
    vec2 TexCoords[3] = isInRain ? ComputeWaterDropletCoords() : DefaultTexCoords;
    /* DRAWBUFFERS:37 */
    gl_FragData[0].rgb = LensFlare + Halo;
    gl_FragData[1].rgb = vec3(texture2D(colortex7, TexCoords[0]).r, texture2D(colortex7, TexCoords[1]).g, texture2D(colortex7, TexCoords[2]).b);
}