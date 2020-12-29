#ifndef UTILITY_UNIFORMS_GLSL
#define UTILITY_UNIFORMS_GLSL 1

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;

// Shadow samplers
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
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

#define debugTex colortex6

// Depth samplers
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D depthtex3;

// Misc samplers
uniform sampler2D texture;
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

#endif