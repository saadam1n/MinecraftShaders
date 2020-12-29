#ifndef GEOMETRY_RAY_GLSL
#define GEOMETRY_RAY_GLSL 1

struct Ray {
    vec3 Origin;
    vec3 Direction;
};

vec3 ExtendRay(in Ray ray, in float dist){
    return ray.Origin + ray.Direction * dist;
}

#endif