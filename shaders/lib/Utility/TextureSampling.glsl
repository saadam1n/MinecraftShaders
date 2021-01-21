#ifndef UTILITY_TEXTURE_SAMPLING_GLSL
#define UTILITY_TEXTURE_SAMPLING_GLSL 1

#include "Uniforms.glsl"

//#define LIGHTING_DEBUG

// Taken from SEUS v10.1
vec4 Cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord, int resolution = 64)
{

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = Cubic(fx);
    vec4 ycubic = Cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

#define TextureAtlas texture

vec4 SampleTextureAtlas(in vec2 coords){
    vec4 color = texture2D(TextureAtlas, coords);
    #ifdef LIGHTING_DEBUG
    color.rgb = vec3(1.0f);
    #endif
    return color;
}

vec4 SampleTextureAtlas(in vec2 coords, float bias){
    vec4 color = texture2D(TextureAtlas, coords, bias);
    #ifdef LIGHTING_DEBUG
    color.rgb = vec3(1.0f);
    #endif
    return color;
}

vec4 SampleTextureAtlasLOD(in vec2 coords, float lod){
    vec4 color = texture2DLod(TextureAtlas, coords, lod);
    #ifdef LIGHTING_DEBUG
    color.rgb = vec3(1.0f);
    #endif
    return color;
}

#endif