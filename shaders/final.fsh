#version 120

#include "lib/Internal/TextureFormats.glsl"
#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/ColorAdjust.glsl"

void main(){
	vec2 TexCoords = ComputeWaterDropletCoords();
    vec4 color = texture2D(colortex7, TexCoords);
	color.rgb = Saturation(color.rgb, 1.1f);
	//color.rgb *= 3.0f;
    //Apply tonemap 
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