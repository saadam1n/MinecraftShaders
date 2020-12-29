#ifndef RANDOM_NOISE_2D_GLSL
#define RANDOM_NOISE_2D_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Utility/Constants.glsl"
#include "Noise1D.glsl"

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
float GenerateNoise2D_0(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 CreateRandomRotation(in vec2 texcoord){
	float Rotation = texture2D(noisetex, texcoord).a;
	return mat2(cos(Rotation), -sin(Rotation), sin(Rotation), cos(Rotation));
}

mat2 CreateRandomRotationScreen(in vec2 texcoord){
	return CreateRandomRotation(texcoord * vec2(viewWidth / noiseTextureResolution, viewHeight / noiseTextureResolution));
}

#endif