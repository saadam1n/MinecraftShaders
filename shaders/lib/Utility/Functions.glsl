#ifndef UTILITY_FUNCTIONS_GLSL
#define UTILITY_FUNCTIONS_GLSL 1

//#extension GL_EXT_gpu_shader4 : enable

void swap(inout float lhs, in float rhs){
    float temp = rhs;
    rhs = lhs;
    lhs = temp;
}

vec3 saturate(vec3 val){
    return clamp(val, vec3(0.0f), vec3(1.0f));
}

vec2 saturate(vec2 val){
    return clamp(val, vec2(0.0f), vec2(1.0f));
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

// https://hub.jmonkeyengine.org/t/round-with-glsl/8186 
vec2 Round(in vec2 coords){
    vec2 signum=sign(coords);//1
    coords=abs(coords);//2
    vec2 coords2 =fract(coords);//3
    coords=floor(coords);//4
    coords2=ceil((sign(coords2-0.5)+1.0)*0.5);//5
    coords=(coords+coords2)*signum;
    return coords;
}

#endif