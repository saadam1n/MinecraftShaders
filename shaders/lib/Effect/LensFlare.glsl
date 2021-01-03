#ifndef EFFECT_LEN_FLARE_GLSL
#define EFFECT_LEN_FLARE_GLSL 1

// http://www.neocodex.us/forum/topic/126112-guide-add-lens-flare-to-seus-shader-pack/ 

#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"

float CalculateLensFlareDistance(in vec2 lhs, in vec2 rhs){
    vec2 dist = lhs - rhs;
    dist.x *= aspectRatio;
    return length(dist);
}

// https://stackoverflow.com/a/5240894/12521279
float ComputeLensFlareHexagon(in vec2 hexagon, in float size, in vec2 position){
    const float HexagonAngle = radians(30.0f);
    const vec2 Edge0 = vec2(0.0f, 1.0f);
    const vec2 Edge1 = vec2(cos( HexagonAngle), sin( HexagonAngle));
    const vec2 Edge2 = vec2(cos(-HexagonAngle), sin(-HexagonAngle));
    position -= hexagon;
    if(
        dot(position, Edge0) < size || 
        dot(position, Edge1) < size || 
        dot(position, Edge2) < size
    ) {
        return 1.0f;
    } else {
        return 0.0f;
    }
}

// Sildurs v1.06 extreme
float ComputeLensFlareCircle(in vec2 circle, in float radius){
    float dist = CalculateLensFlareDistance(gl_TexCoord[0].st, circle) / radius;
    return exp(-dist * dist);
}

float ComputeLensFlareCircle(in vec2 light, const float blend, in float radius){
    return ComputeLensFlareCircle(mix(light, vec2(0.5f), blend), radius);
}

vec3 ComputeLensFlare(void){
    float SunDot = dot(normalize(sunPosition), vec3(0.0f, 0.0f, -1.0f));
    if(SunDot < -0.4f){
        return vec3(0.0f);
    }
    // Get the screen screen position
    // Then split it up into segments between sun screen pos and center pos
    // Then draw the lens flare stuff there
    vec4 SunNDC = gbufferProjection * vec4(sunPosition, 1.0f);
    vec2 SunPos = (SunNDC.xy / SunNDC.w) * 0.5f + 0.5f;
    if(!IsInRange(SunPos, vec2(-0.1f), vec2(1.1f)) || texture2D(depthtex0, SunPos).r != 1.0f){
        return vec3(0.0f);
    }
    vec3 LensFlareAccum = vec3(0.0f);
    LensFlareAccum += ComputeLensFlareCircle(SunPos, 0.55f, 0.06f) * vec3(0.8f, 0.1f, 0.07f);
    LensFlareAccum += ComputeLensFlareCircle(SunPos, 0.85f, 0.07f) * vec3(1.0f , 0.35f, 0.1f);
    LensFlareAccum += ComputeLensFlareCircle(SunPos, 1.15f, 0.08f) * vec3(0.7f , 0.7f, 0.1f ) ;
    LensFlareAccum += ComputeLensFlareCircle(SunPos, 1.45f, 0.09f) * vec3(0.15f , 0.4f, 0.9f ) ;
    return LensFlareAccum * 0.3f * SunDot;
}

#endif