#ifndef GEOMETRY_PLANE_GLSL
#define GEOMETRY_PLANE_GLSL 1

#include "Ray.glsl"

struct Plane {
    vec3 Position;
    vec3 Normal;
};

float Intersect(in Ray ray, in Plane plane){
    float div = dot(ray.Direction, plane.Normal);
    float num = dot(plane.Position - ray.Origin, plane.Normal);
    return num / div;
}

#endif