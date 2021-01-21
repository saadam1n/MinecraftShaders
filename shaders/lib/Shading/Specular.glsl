#ifndef SHADING_SPECULAR_GLSL
#define SHADING_SPECULAR_GLSL

float ComputeSpecular(in float k, in float s, in vec3 n, in vec3 v, in vec3 l){
    // Am I going insane?
    n = normalize(n);
    v = normalize(v);
    l = normalize(l);
    // Blinn phong
    vec3 h = normalize(v + l);
    float NoH = max(dot(n, h), 0.0f);
    return s * pow(NoH, k);
}

#endif