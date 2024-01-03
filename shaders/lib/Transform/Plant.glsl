#ifndef TRANSFORM_PLANT_GLSL
#define TRANSFORM_PLANT_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Misc/BlockID.glsl"

const float PhaseMult2D = 800.0f;
float Frequency2D = mix(2.0f, 5.0f, rainStrength); //Frequncy
float Amplitude2D = mix(0.14f, 0.2f, rainStrength);

vec2 PlantDisplacement2D(in vec2 pos){
	vec2 SineWave = vec2(0.0f);
	SineWave += pos * PhaseMult2D;
	SineWave += Frequency2D * frameTimeCounter;
	return sin(SineWave) * Amplitude2D;
}

vec2 PlantTransform2D(in vec2 plant){
	vec2 Offset = vec2(0.0f);
    Offset.xy = PlantDisplacement2D(plant.xy);
	Offset *= sin(2 * frameTimeCounter) + sin(3.1415 * frameTimeCounter) * 0.5f;
	plant.xy += Offset;
	return plant;
}

const float PhaseMult3D = 80.0f;
float Frequency3D = mix(2.0f, 5.0f, rainStrength); //Frequncy
float Amplitude3D = mix(0.05f, 0.1f, rainStrength);

vec3 PlantDisplacement3D(in vec3 pos){
	vec3 SineWave = vec3(0.0f);
	SineWave += pos * PhaseMult3D;
	SineWave += Frequency3D * frameTimeCounter;
	return sin(SineWave) * Amplitude3D;
}

vec3 PlantTransform3D(in vec3 plant){
	vec3 Offset = vec3(0.0f);
    Offset.xyz = PlantDisplacement3D(plant.xyz);
	Offset *= sin(2 * frameTimeCounter) + sin(3.1415 * frameTimeCounter) * 0.5f;
	plant.xyz += Offset;
	return plant;
}

// Applies to grass, tall grass, wheat, etc
vec4 TransformTallGrass(in vec2 midtexcoord){
    if(gl_MultiTexCoord0.t < midtexcoord.t){
        #ifdef SHADOW_PASS
        vec4 WorldPosition = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
        #else
        vec4 WorldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
        #endif
        vec3 TransformPosition = WorldPosition.xyz + cameraPosition;
        TransformPosition.xz = PlantTransform2D(TransformPosition.xz);
        TransformPosition -= cameraPosition;
        #ifdef SHADOW_PASS
        return gl_ProjectionMatrix * shadowModelView * vec4(TransformPosition, 1.0f);
        #else
        return gl_ProjectionMatrix * gbufferModelView * vec4(TransformPosition, 1.0f);
        #endif
    } else {
        return ftransform();
    }
}

vec4 TransformLeaves(void){
    #ifdef SHADOW_PASS
    vec4 WorldPosition = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
    #else
    vec4 WorldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
    #endif
    vec3 TransformPosition = WorldPosition.xyz + cameraPosition;
    TransformPosition = PlantTransform3D(TransformPosition);
    TransformPosition -= cameraPosition;
    #ifdef SHADOW_PASS
    return gl_ProjectionMatrix * shadowModelView * vec4(TransformPosition, 1.0f);
    #else
    return gl_ProjectionMatrix * gbufferModelView * vec4(TransformPosition, 1.0f);
    #endif
}

#endif