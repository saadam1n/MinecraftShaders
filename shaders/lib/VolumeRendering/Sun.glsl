#ifndef VOLUME_RENDERING_SUN_GLSL
#define VOLUME_RENDERING_SUN_GLSL 1

#include "SunProperties.glsl"

struct Light {
    vec3 Color;
    vec3 Direction;
};

// use the simplified model for faster performance
vec3 ComputeLimbDarkening(in float ndist){
    ndist = 1.0f - ndist;
    float mu = sqrt(1.0f - ndist * ndist);
    vec3 LimbDarkening = pow(vec3(mu), vec3(0.397 , 0.503 , 0.652));
    return LimbDarkening;
}

vec3 ComputeSunColor(in vec3 light, in vec3 dir){
    float dot_dist = dot(light, dir);
    if(dot_dist < SunSpotSize){
        return vec3(0.0f);
    }
    dot_dist -= SunSpotSize;
    dot_dist /= SunSpotSize;
    vec3 LimbDarkening = ComputeLimbDarkening(dot_dist);
    vec3 ViewPos =  GetCameraPositionEarth();
    float dist = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    Ray SunRay;
    SunRay.Origin = ViewPos;
    SunRay.Direction = dir;
    vec3 Transmittance = ComputeTransmittance(SunRay, dist);
    return Transmittance * SunColor * LimbDarkening;
}

// Passing in ViewTransmittance did not work
vec3 ComputeSunColor(in vec3 light, in vec3 dir, in vec3 opticaldepth){
    float dot_dist = dot(light, dir);
    if(dot_dist < SunSpotSize){
        return vec3(0.0f);
    }
    dot_dist -= SunSpotSize;
    dot_dist /= SunSpotSize;
    vec3 LimbDarkening = ComputeLimbDarkening(dot_dist);
    vec3 transmittance = Transmittance(opticaldepth);
    return transmittance * SunColor * LimbDarkening;
}

#endif