#ifndef SHADING_SPECULAR_GLSL
#define SHADING_SPECULAR_GLSL

#include "../VolumeRendering/Atmosphere.glsl"
#include "../VolumeRendering/Clouds.glsl"

vec3 ComputeSkyReflection(in vec3 c, in float s, in vec3 d, in vec3 l, in vec3 v, in vec3 n, in vec3 b = vec3(0.0204078134121f)){
    v = normalize(v);
    n = normalize(n);
    float mu = max(dot(-v, n), 0.0f);
    vec3 fresnel = b + (1.0f - b) * pow(1.0f - mu, 5.0f); // Use pow since I think this is when pow becomes faster than multiplying it 
    vec3 reflectedVector = normalize(reflect(v, n));
    vec3 skyreflection = ComputeAtmosphericScattering(SunDirection, reflectedVector); 
    float SunDot = dot(SunDirection, reflectedVector);
    if(SunDot > SunSpotSize) {
        skyreflection += ComputeSunColor(SunDirection, reflectedVector);
    }
    skyreflection.rgb = Draw2DClouds(reflectedVector, isNight ? MoonSkyColor : l, skyreflection.rgb);
    return mix(c, skyreflection, fresnel * s);//mix(c, skyreflection, fresnel * s) ;
}

float ComputeSpecular(in float k, in float s, in vec3 n, in vec3 v, in vec3 l){
    // Am I going insane?
    n = normalize(n);
    v = normalize(v);
    l = normalize(l);
    // Blinn phong
    vec3 h = normalize(v + l);
    float NoH = max(dot(n, h), 0.0f);
    return s * pow(NoH, k);
}

#endif