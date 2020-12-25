#ifndef TRANSFORM_EYE_GLSL
#define TRANSFORM_EYE_GLSL

// Should be flat varying from vert shader
// But I'm lazy
vec3 GetEyePositionShadow(void){
    vec4 eye = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0f, 0.0f, 0.1f, 1.0f);
    return eye.xyz;
}

// Same for this
vec3 GetEyePositionWorld(void){
    vec4 eye = gbufferModelViewInverse * vec4(0.0f, 0.0f, 0.1f, 1.0f);
    return eye.xyz + cameraPosition;
}


#endif