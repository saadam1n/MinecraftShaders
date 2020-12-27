#ifndef VOLUME_RENDERING_SKY_GLSL
#define VOLUME_RENDERING_SKY_GLSL 1

#include "Atmosphere.glsl"
#include "Sun.glsl"

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir){
    vec3 temp;
    return ComputeAtmosphericScattering(light, dir, temp);
}

// https://www.shadertoy.com/view/llffzM 
const vec3 SkyColor = vec3(0.39, 0.57, 1.0);
const vec3 SkyGradientBottom = vec3(0.8, 0.9, 1.0f);

vec3 ComputeInaccurateAtmosphere(in vec3 light, in vec3 dir, out vec3 sun) {
    vec3 Rayleigh = mix(SkyGradientBottom, SkyColor, min(dir.y + 0.5f, 1.0f)); 
    float cosTheta = dot(light, dir);
    float Mie = pow(cosTheta * 0.5f + 0.5f, 42.0f) * 0.3f;
    return Rayleigh + Mie;
}

vec3 ComputeInaccurateSun(in vec3 light, in vec3 dir, in vec3 absorption) {
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    return vec3(0.0f);
}

#define PHYSICALLY_BASED_ATMOSPHERE // Use a physically based model for rendering the atmosphere

vec3 ComputeAtmosphereColor(in vec3 light, in vec3 dir, out vec3 aux){
    #ifdef PHYSICALLY_BASED_ATMOSPHERE
    return ComputeAtmosphericScattering(light, dir, aux);
    #else
    return ComputeInaccurateAtmosphere(light, dir, aux);
    #endif
}

vec3 ComputeAtmosphereColor(in vec3 light, in vec3 dir){
    vec3 temp;
    return ComputeAtmosphereColor(light, dir, temp);
}

vec3 GetSkyTopColor(void){
    float Input = abs((float(worldTime) / 24000.0f) * 2.0f - 1.0f);
    // RED
    float Red = 0.5 * pow(Input, 7.0f);
    // GREEN
    float Green = 0.7 * pow(Input, 2.0f);
    // BLUE
    float Blue = 0.9 * pow(Input, 0.7f);
    return mix(vec3 (Red, Green, Blue), skyColor, 0.5f);
}

const float StarThreshold = 0.99f;

vec3 ComputeStars(in vec3 dir){
    vec2 NoiseCoord = dir.xy;
    float StarNoise = texture2D(noisetex, NoiseCoord).r;
    return vec3(step(StarThreshold, StarNoise));
}

#endif