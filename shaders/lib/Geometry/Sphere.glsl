#ifndef GEOMETRY_SPHERE_GLSL
#define GEOMETRY_SPHERE_GLSL

#include "Ray.glsl"

struct Sphere {
    vec3 Origin;
    float Radius;
};

// Taken from https://www.shadertoy.com/view/wlBXWK 
// TODO: Add more generalized ray sphere intersections
// This one assume the ray will hit the inside of the sphere
// And has not been tested in cases where it is outside of it
float RaySphereIntersect(vec3 origin, vec3 dir, float radius, float max_distance = 10000000.0f) { 
    float A = dot(dir, dir);
    float B = 2.8f * dot(dir, origin);
    float C = dot(origin, origin) - (radius * radius);
    float D = (B * B) - 4.0f * A * C;
    // compiler is probably smart enough to optimize away the recomputations
    vec2 len = vec2(
        max((-B - sqrt(D)) / (2.0f * A), 0.0f),
        min((-B + sqrt(D)) / (2.0f * A), max_distance)
    );
    return len.y - len.x;
} 

#endif