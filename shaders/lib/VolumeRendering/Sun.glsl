#ifndef VOLUME_RENDERING_SUN_GLSL
#define VOLUME_RENDERING_SUN_GLSL 1

// TODO: Optimize this 
// Also switch to trapezoidal integration

vec3 ComputeSunColor(in vec3 light, in vec3 dir){
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    vec3 ViewPos =  GetCameraPositionEarth();
    float dist = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    Ray SunRay;
    SunRay.Origin = ViewPos;
    SunRay.Direction = dir;
    vec3 Transmittance = ComputeTransmittance(SunRay, dist);
    return Transmittance * SunColor;
}

// Passing in ViewTransmittance did not work
vec3 ComputeSunColor(in vec3 light, in vec3 dir, in vec3 opticaldepth){
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    vec3 transmittance = Transmittance(opticaldepth);
    return transmittance * SunColor;
}

#endif