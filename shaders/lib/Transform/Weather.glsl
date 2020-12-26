#ifndef TRANSFORM_WEATHER_GLSL
#define TRANSFORM_WEATHER_GLSL 1

#include "../Utility/Uniforms.glsl"

#define SHIFTING_RAIN_STYLE 0 // The style of the rain shift. 0 = No rain shift. 1 = My rain shift. 2 = Super shader V5.0 rain shift. [0 1 2]
#define SHIFTING_RAIN_AMPLITUDE 1.5f
#define WEATHER_DENSITY 1.0f // How fast and small weather particles (rain and snow) are [0.25f 0.5f 0.75f 1.0f 1.25f 1.5f 1.75 2.0f]

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

vec4 ShiftingRainStandard(void){
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

// Taken from Kuda 6.5.56
vec4 ShiftedRainKUDA6556(void){
    vec4 glPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    glPos.xyz += cameraPosition;
    bool isTop = glPos.y > cameraPosition.y + 5.0f;
    if (!isTop) {
        glPos.xz += vec2(1.0, 0.0);
    }
    glPos.xyz -= cameraPosition;
    glPos = gl_ProjectionMatrix * gbufferModelView * glPos;
    return glPos;
}

vec4 WeatherTransform(void){
    #if (SHIFTING_RAIN_STYLE == 0)
    return ShiftingRainStandard();
    #endif
    #if (SHIFTING_RAIN_STYLE == 1)
    return ShiftingRainSuperShaders();
    #endif
    #if (SHIFTING_RAIN_STYLE == 2)
    return ShiftedRainKUDA6556();
    #endif
}


#endif