#ifndef UTILITY_FUNCTIONS_GLSL
#define UTILITY_FUNCTIONS_GLSL 1

//#extension GL_EXT_gpu_shader4 : enable

vec3 saturate(vec3 val){
    return clamp(val, vec3(0.0f), vec3(1.0f));
}

float saturate(float val){
    return clamp(val, 0.0f, 1.0f);
}

float dotunorm(vec3 lhs, vec3 rhs){
    return saturate(dot(lhs, rhs));
}

bool IsInRange(in vec3 vec, in vec3 lower, in vec3 upper){
    return all(greaterThan(vec, lower)) && all(lessThan(vec, upper));
}

bool IsInRange(in vec2 vec, in vec2 lower, in vec2 upper){
    return all(greaterThan(vec, lower)) && all(lessThan(vec, upper));
}

#endif