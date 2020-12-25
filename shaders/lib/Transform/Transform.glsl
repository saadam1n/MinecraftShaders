#ifndef TRANSFORM_TRANSFORM_GLSL 
#define TRANSFORM_TRANSFORM_GLSL 1

#include "../Misc/BlockID.glsl"
#include "Plant.glsl"
#include "Distort.glsl"
#include "Weather.glsl"

vec4 TransformVertex(in vec3 entity = vec3(0.0f), in vec2 midtex = vec2(0.0f)){
    #ifdef GBUFFERS_WEATHER
    return WeatherTransform();
    #else
    vec4 TransfomedPos;
    #ifdef WAVING_PLANTS
    float ID = entity.x;
    if(IS_TALL_GRASS(ID)){
        TransfomedPos = TransformTallGrass(midtex);
    } else {
        TransfomedPos =  ftransform();
    }
    #else
    TransfomedPos = ftransform();
    #endif
    #ifdef SHADOW_PASS
    TransfomedPos.xyz = DistortShadow(TransfomedPos.xyz);
    #endif
    return TransfomedPos;
    #endif
}

#endif