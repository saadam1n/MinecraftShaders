#version 120

#include "lib/Internal/TextureFormats.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/Functions.glsl"
#include "lib/Utility/ColorAdjust.glsl"
#include "lib/Effect/Tonemapping.glsl"
#include "lib/Random/Noise3D.glsl"

flat varying float inRain;
flat varying float Exposure;

#define HIGH_DYNAMIC_RANGE

const bool colortex7MipmapEnabled = false;

void main(){
	vec2 TexCoords;
	TexCoords = gl_TexCoord[0].st;
    vec4 color = texture2DLod(colortex7, TexCoords, 0.0f).rgba;
	//color.rgb = vec3(GenerateNoise3D_24(vec3(gl_TexCoord[0].st, 0.0f)));
	color.rgb = ComputeHighDynamicRangeExposure(color.rgb, Exposure);
	//#ifdef HIGH_DYNAMIC_RANGE
	//if(gl_FragCoord.x > viewWidth / 2) // Uncomment to see side by side comparison
	//color.rgb = saturate(color.rgb);
	//color.rgb = HighDynamicRange(color.rgb);
	//#endif
	// saturation boosting is never the way to do it
	//color.rgb = Saturation(color.rgb, 1.3f);
	//color.rgb *= 3.0f;
    //Apply tonemap 
	// I like ACES filmic tonemapping due to the contrast increase without making everything dark
	// TODO: add options for other tonemaps
	color.rgb = ComputeTonemap(color.rgb);
	#ifdef FILM_GRAIN
	color.rgb = ComputeFilmGrain(color.rgb);
	#endif
	color.rgb = (color.rgb);
	//color.rgb = texture2D(noisetex, gl_TexCoord[0].st).rga;
	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
    gl_FragColor = color;
}