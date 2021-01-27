#ifndef VOLUME_RENDERING_ATMOSPHERE_PROPERTIES_GLSL
#define VOLUME_RENDERING_ATMOSPHERE_PROPERTIES_GLSL 1

#include "Phase.glsl"
#include "SunProperties.glsl"
#include "../Geometry/Ray.glsl"
#include "../Utility/Uniforms.glsl"

#define KM_SIZE 1000.0f

const float ScaleHeightRayleigh = 7.994f * KM_SIZE;
const float ScaleHeightMie = 1.200f * KM_SIZE;

const vec3 ScatteringRayleigh = vec3(5.8e-6, 13.5e-6, 33.1e-6); // alt val: vec3(5.5e-6, 13.0e-6, 22.4e-6), real val: vec3(5.8e-6, 13.5e-6, 33.1e-6)
const vec3 AbsorptionRayleigh = vec3(0.0f); // Negligible 
const vec3 ExtinctionRayleigh = ScatteringRayleigh + AbsorptionRayleigh;

const float ScatteringMie = 21e-6;
const float AbsorptionMie = 1.1f * ScatteringMie;
const float ExtinctionMie = ScatteringMie + AbsorptionMie;

const vec3 ScatteringOzone = vec3(0.0f); // Ozone does not scatter light
const vec3 AbsorptionOzone = vec3(2.04e-5, 4.97e-5, 1.95e-6); //vec3(0.650,1.881,0.085) * 1.0e-6; // Values taken from A Scalable and Production Ready Sky and Atmosphere Rendering Technique
//vec3(1.36820899679147f,3.31405330400124f, 0.13601728252538f) *  6.0e-6 * 2.504; // https://www.shadertoy.com/view/MllBR2 
const vec3 ExtinctionOzone = ScatteringOzone + AbsorptionOzone;


const float EarthRadius = 6360.0f * KM_SIZE;
const float AtmosphereHeight = 80.0f * KM_SIZE;
const float AtmosphereRadius = AtmosphereHeight + EarthRadius;


float CalculateDensityRayleigh(float h){
    return exp(-h / ScaleHeightRayleigh);
}

float CalculateDensityMie(float h){
    return exp(-h / ScaleHeightMie);
}

// Ozone function:
// 0.07\left(\frac{1}{1+\left(x-29.874\right)^{2}}\right)^{0.7}
// Based of an approximation of https://www.shadertoy.com/view/wlBXWK 
// Original function:
// c\left(x\right)=\max\left(\min\left(x,\ 1\right),0\right) this is clamp()
// c\left(\frac{1.0}{\frac{\cosh\left(30-x\right)}{3}}\cdot\exp\left(-\frac{x}{7.994}\right)\right)
// x in both functions is in kilometers
// I'd galdy appreciate if someone finds the correct function or a more accurate function

float CalculateDensityOzone(float h){
    return exp(-h / ScaleHeightMie);
}

vec3 CalculateAtmosphericDensity(float height) {
    vec3 Density;
    Density.xy = exp(-height / vec2(ScaleHeightRayleigh, ScaleHeightMie));
    float x = height / KM_SIZE; // The function squares x, and x is supposed to be in km
    x  = x - 29.874f;
    x *= x;
    x  = 1.0f / (1.0f + x);
    x  = pow(x, 0.7);
    x *= 0.07f;
    Density.z = x;
    return Density;
}

float CalculateAltitude(in vec3 pos){
    return length(pos) - EarthRadius;
}

vec3 CalculateAtmosphericDensity(vec3 pos) {
    return CalculateAtmosphericDensity(CalculateAltitude(pos));
}

vec3 CalculateAtmosphericDensity(in Ray odray, in float pos, in float len){
    return CalculateAtmosphericDensity(odray.Origin + odray.Direction * (pos + 0.5f * len));
}

#endif