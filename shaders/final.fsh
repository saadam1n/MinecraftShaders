#version 120

varying vec2 texcoords;

#include "util/uniforms.glsl"

vec3 FilmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	return color;
}

vec3 ACESFilmicTonemapping(vec3 color) {
    return clamp((color*(2.51f*color+0.03f))/(color*(2.43f*color+0.59f)+0.14f), vec3(0.0f), vec3(1.0f));
}

//#define DEBUG

void main(){
    vec4 color = texture2D(colortex7, texcoords);
    //Apply tonemap 
	color.rgb = ACESFilmicTonemapping(color.rgb);
	#ifdef DEBUG
	color = texture2D(debugTex, texcoords);
	#endif
	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
    gl_FragColor = color;
}