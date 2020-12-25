#ifndef TRANSFORM_PLANT_GLSL
#define TRANSFORM_PLANT_GLSL 1

#include "../uniforms.glsl"
#include "../misc/plant_id.glsl"

const float PosStrength = 20.0f;
float WaveStrength = mix(2.0f, 5.0f, rainStrength); //Frequncy
float Amplitude = mix(0.14f, 0.2f, rainStrength);

vec2 PlantDisplacement(in vec2 pos){
	vec2 SineWave = vec2(0.0f);
	SineWave += pos * PosStrength;
	SineWave += WaveStrength * frameTimeCounter;
	return sin(SineWave) * Amplitude;
}

vec3 PlantTransform(in vec3 plant){
	vec3 Offset = vec3(0.0f);
    Offset.xz = PlantDisplacement(plant.xz);
	Offset *= sin(2 * frameTimeCounter) + sin(3.1415 * frameTimeCounter) * 0.5f;
	plant.xyz += Offset;
	return plant;
}


// Applies to grass, tall grass, wheat, etc
vec4 TransformGrass(in vec3 entity, in vec2 midtexcoord){
    if(IsGrass(entity.x) && gl_MultiTexCoord0.t < midtexcoord.t){
        #ifdef SHADOW_PASS
        vec4 WorldPosition = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
        #else
        vec4 WorldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex; 
        #endif
        vec3 TransformPosition = WorldPosition.xyz + cameraPosition;
        TransformPosition = PlantTransform(TransformPosition);
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

#endif