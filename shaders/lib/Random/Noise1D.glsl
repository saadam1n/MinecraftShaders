#ifndef RANDOM_NOISE_1D_GLSL
#define RANDOM_NOISE_1D_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Utility/Constants.glsl"

// A lot of these were taken from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
//
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float GenerateNoise1D_0(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

// TODO: loop through all rows
vec4 GetRandomNumber(void){
    vec2 noisecoords;
    noisecoords.x = float(frameCounter) / float(noiseTextureResolution);
    // Do a bunch of modulo stuff to loop through all rows
    // But im lazy
    return texture2D(noisetex, noisecoords);
}

#endif