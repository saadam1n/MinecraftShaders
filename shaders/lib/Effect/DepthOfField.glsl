#ifndef EFFECT_DEPTH_OF_FIELD_GLSL 
#define EFFECT_DEPTH_OF_FIELD_GLSL

#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"

/*
A  - Aperture diameter
f  - Focal length
S1 - Focal distance
S2 - Fragment distance
All units should be the same, preferably in meters
*/
float ComputeCircleOfConfusion(in float A, in float f, in float S1, in float S2){
    return A * (abs(S2-S1) / S2) * (f / (S1 - f));
}

float ComputeCircleOfConfusion(in float center, in float dist){
    // return 0.02f;
    // I keep the focal length high at 1 meter
    // This makes close up objects blurry, which is particualry useful for making the area behind translucent objects blurry
    // This allows me to put it in one pass after forward rendering has been done, but it is not the greatest solution
    return min(ComputeCircleOfConfusion(0.424f, 0.5f, center, dist), 0.02f);
}

#endif