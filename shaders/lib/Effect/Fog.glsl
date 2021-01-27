#ifndef EFFECT_FOG_GLSL
#define EFFECT_FOG_GLSL 1

#include "../Shading/Structures.glsl"
#include "../Utility/Uniforms.glsl"

float FogExtinction = mix(0.001f, 0.0023f, rainStrength);
const float FogScaleHeight = 20.0f;
const float FogStrength = 1.3f;
const float FogMaxDistance = 1000000.0f;

// TODO:
// - Proper fog inputs
// - Cave fog
// - Rain fog
// - Just redo the fog so it is better
// - Ray marched fog
// - Make rain fog not affect cave fog

vec3 ComputeFog(in vec3 world, in vec3 view, in vec3 color, in float sky = 1.0f){
    if(isEyeInWater == 1){
        //UE4 coeff
        vec3 coeff = vec3(0.35, 0.07, 0.03);
        vec3 transmittance = exp(-coeff * length(view));

        return transmittance * color;
    } 
    // Extinction isn't the best word here, but whatever
    // TODO: use surface.View instead of position - cameraPosition for performance increase
    float foggyness = 1.0f - exp(-FogExtinction * min(length(view), FogMaxDistance));
    // Cave fog idea taken from SEUS V10.1
    float CaveFog = 1.0f - sky;
    CaveFog = pow(CaveFog, 4.5f);
    foggyness = (1.0f + pow(CaveFog, 3.0f)) * foggyness * FogStrength;
    vec3 FogColor = mix(vec3(1.0f), vec3(0.05f, 0.1f, 0.45f), CaveFog);
    // Now apply height fog, I use a very basic example of multipling it 
    // A physically based approcah would ray march it instead
    // Also is there a spell check plugin for vscode?
    float FogHeight = max(world.y - 64.0f, 0.0f);
    foggyness = foggyness * exp(-FogHeight / FogScaleHeight);
    return mix(color, FogColor, foggyness);
}

#endif