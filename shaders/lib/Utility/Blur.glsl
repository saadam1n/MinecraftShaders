#ifndef UTILITY_BLUR_GLSL
#define UTILITY_BLUR_GLSL 1

#include "Constants.glsl"

float Gaussian(float stddev, float x){
    float stddev2 = stddev * stddev;
    float stddev2_2 = stddev2 * 2.0f;
    return pow(MATH_PI * stddev2_2, -0.5f) * exp(-(x * x / stddev2_2));
}

float Guassian(in float sigma, in float x){
    float sigma2_2 = 2.0f * sigma * sigma;
    return (1.0f / sqrt(MATH_PI * sigma2_2)) * exp(x * x / sigma2_2);
}

#endif