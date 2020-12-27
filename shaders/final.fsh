#version 120

#include "lib/Internal/TextureFormats.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/ColorAdjust.glsl"

flat varying float inRain;
flat varying float Exposure;

#define HIGH_DYNAMIC_RANGE

void main(){
	vec2 TexCoords;
	if(inRain == 1.0f){
		TexCoords = ComputeWaterDropletCoords();
	} else {
		TexCoords = gl_TexCoord[0].st;
	}
    vec4 color = texture2D(colortex7, TexCoords);
	color.rgb = ComputeExposureToneMap(color.rgb, Exposure);
	#ifdef HIGH_DYNAMIC_RANGE
	//if(gl_FragCoord.x > viewWidth / 2) // Uncomment to see side by side comparison
	color.rgb = HighDynamicRange(color.rgb);
	#endif
	// saturation boosting is never the way to do it
	//color.rgb = Saturation(color.rgb, 1.3f);
	//color.rgb *= 3.0f;
    //Apply tonemap 
	// I like ACES filmic tonemapping due to the contrast increase without making everything dark
	// TODO: add options for other tonemaps
	color.rgb = ACESFilmicTonemapping(color.rgb);
	#ifdef FILM_GRAIN
	color.rgb = ComputeFilmGrain(color.rgb);
	#endif
	#ifdef DEBUG
	color = texture2D(debugTex,  gl_TexCoord[0].st);
	#endif
	//color.rgb = texture2D(noisetex, gl_TexCoord[0].st).rga;
	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
    gl_FragColor = color;
}