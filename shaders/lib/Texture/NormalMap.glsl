#ifndef TEXTURE_NORMAL_MAP_GLSL
#define TEXTURE_NORMAL_MAP_GLSL 1

#include "../Utility/Uniforms.glsl"

#ifdef VERTEX

#include "../Utility/Attributes.glsl"

mat3 CreateTBN(void){
    vec3 Normal = gl_Normal;
    vec3 Tangent = at_tangent.xyz / at_tangent.w;
    vec3 Bitangent = cross(Normal, Tangent);
    mat3 TBN_Matrix = mat3(gbufferModelViewInverse) * gl_NormalMatrix * mat3(Tangent, Bitangent, Normal);
    TBN_Matrix[0] = normalize(TBN_Matrix[0]);
    TBN_Matrix[1] = normalize(TBN_Matrix[1]);
    TBN_Matrix[2] = normalize(TBN_Matrix[2]);
    return TBN_Matrix;
}

#endif

// Not labPBR
vec3 ComputeNormalMap(in mat3 TBN_Matrix){
    vec3 NormalMap = texture2D(normals, gl_TexCoord[0].st).rgb * 2.0f - 1.0f;
    return normalize(TBN_Matrix * NormalMap);
}

#endif