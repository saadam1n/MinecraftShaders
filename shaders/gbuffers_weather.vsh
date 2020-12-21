#version 120

attribute vec4 mc_midTexCoord;

varying vec3 Normal;

#include "util/uniforms.glsl"

#define SHIFTING_RAIN_STYLE 0 // The style of the rain shift. 0 = No rain shift. 1 = My rain shift. 2 = Super shader V5.0 rain shift. [0 1 2]

// Based on Super Shaders V5.0
vec4 ShiftingRainSuperShaders(void){
    vec4 glPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    vec3 WorldPos = glPos.xyz + cameraPosition;
    bool isTop = WorldPos.y > cameraPosition.y + 5.0f;
    if (!isTop) {
        WorldPos.xz += vec2(2.3,1.0) + sin(frameTimeCounter) * sin(frameTimeCounter) * sin(frameTimeCounter) * vec2(2.1,0.6);
    }
	WorldPos.xz -= (vec2(3.0,1.0) + sin(frameTimeCounter) * sin(frameTimeCounter) * sin(frameTimeCounter) * vec2(2.1,0.6)) * 0.25;
    WorldPos -= cameraPosition;
    glPos = gl_ProjectionMatrix * gbufferModelView * vec4(WorldPos, 1.0f);
    return glPos;
    return vec4(0.0f);
}

vec4 ShiftingRain(void){
    vec4 glPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    vec3 WorldPos = glPos.xyz + cameraPosition;
    bool isTop = WorldPos.y > cameraPosition.y + 5.0f;
    if(isTop){
        WorldPos.xz += SHIFTING_RAIN_AMPLITUDE * (sin(0.5 * frameTimeCounter) + cos(frameTimeCounter));
    }
    WorldPos.xz -= SHIFTING_RAIN_AMPLITUDE * (sin(frameTimeCounter) - (cos(0.2f * frameTimeCounter) * 3 * sin(0.4f * frameTimeCounter)));
    WorldPos -= cameraPosition;
    glPos = gl_ProjectionMatrix * gbufferModelView * vec4(WorldPos, 1.0f);
    return glPos;
}

void main(){
    
    gl_Position = 
    #if (SHIFTING_RAIN_STYLE == 0)
    ftransform();
    #endif
    #if (SHIFTING_RAIN_STYLE == 1)
    ShiftingRain();
    #endif
    #if (SHIFTING_RAIN_STYLE == 2)
    ShiftingRainSuperShaders();
    #endif
    Normal = gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st * WEATHER_DENSITY;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}