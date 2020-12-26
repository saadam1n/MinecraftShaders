#ifndef MATERIAL_LABPBR_GLSL
#define MATERIAL_LABPBR_GLSL

// See labPBR docs for more details
// https://github.com/rre36/lab-pbr/wiki 

#include "../Utility/Uniforms.glsl"

struct LabPBR_Info{
    // Normal Texture
    vec3 Normal;
    float AmbientOcclusion;
    // TODO: parallax mapping
    // Specular texture
    float PerceptualSmoothness;
    float Roughness;
    float BaseReflectivity; // F0
    vec3 RefractiveIndex;
    vec3 ExtinctionCoefficient;
    float Porosity;
    float SubsurfaceScattering;
    float Emission; 
};

LabPBR_Info ConstructLabPBR_Info(void){
    LabPBR_Info Info;
    vec4 NormalTextureInput = texture2D(normals, gl_TexCoord[0].st);
    vec4 SpecularTextureInput = texture2D(specular, gl_TexCoord[0].st);
    Info.Normal.xy = NormalTextureInput.xy
    Info.Normal.z = sqrt(1.0f - dot(NormalTextureInput.xy, NormalTextureInput.xy));
    Info.AmbientOcclusion = NormalTextureInput.b;

    return Info;

}
// TODO: fill the rest of this out

#endif