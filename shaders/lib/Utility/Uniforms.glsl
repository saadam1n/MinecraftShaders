#ifndef UTILITY_UNIFORMS_GLSL
#define UTILITY_UNIFORMS_GLSL 1

#ifndef INTERNAL_SHADER_SETTINGS_GLSL
#define INTERNAL_SHADER_SETTINGS_GLSL 1

const int shadowMapResolution = 2048; // The shadow resolution [256 512 1024 1572 2048 3072 4096 8192 16384]
const float shadowDistance = 128; // How large the shadow map is [16 32 64 72 96 128 180 256]
const int noiseTextureResolution = 512;

#define ShaderPrecision highp

precision ShaderPrecision int;
precision ShaderPrecision float;

#endif

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

// Color samplers
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;

#define debugTex colortex6

// Depth samplers
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D depthtex3;

// Misc samplers
uniform sampler2D texture;
uniform sampler2D tex;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

uniform float frameTimeCounter;
uniform int worldTime;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float far;
uniform float near;

uniform vec3 sunPosition;

uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float screenBrightness;
uniform int frameCounter;

uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;  

uniform float centerDepthSmooth;
uniform float aspectRatio;

uniform float eyeAltitude;
uniform int isEyeInWater;

uniform sampler2D normals;
uniform vec3 shadowLightPosition;
uniform sampler2D specular;
uniform ivec2 atlasSize;

#ifdef GBUFFERS
sampler2D GetPrecomputedOpticalDepth(){
    return gaux4;
}
#else
sampler2D GetPrecomputedOpticalDepth(){
    return depthtex1;
}
#endif

#define PrecomputedOpticalDepth GetPrecomputedOpticalDepth()

uniform vec3 moonPosition;
uniform vec3 upPosition;



// Custom Uniforms

uniform vec2 ScreenSize;
uniform vec2 TexelSize;
uniform float CenterDistance;
uniform vec3 LightDirection;
uniform vec3 SunDirection;
uniform vec3 MoonDirection;
uniform bool isInNether;
uniform bool isInRain;

#endif