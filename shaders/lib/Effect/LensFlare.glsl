#ifndef EFFECT_LEN_FLARE_GLSL
#define EFFECT_LEN_FLARE_GLSL 1

#include "../Utility/Uniforms.glsl"
#include "../Geometry/Ray.glsl"

mat4 LensFlareTransform = gbufferProjection * gbufferModelView;

vec2 ComputeLensFlareLocation(in Ray lfray, in float dist){
    vec3 Location = ExtendRay(lfray, dist);
    vec4 ndc = LensFlareTransform * vec4(Location, 1.0f);
    vec2 Coords = ndc.xy / ndc.w;
    Coords = Coords * 0.5f + 0.5f;
    return Coords;
}

vec3 ComputeLensFlare(in vec3 sun, in vec3 direction, in vec3 cameradir){
    return vec3(0.0f);
    vec3 viewout = cameradir * 3.0f;
    Ray LensFlareRay;
    LensFlareRay.Origin = sun;
    LensFlareRay.Direction = normalize(viewout - sun);
    vec2 BlueLocation = ComputeLensFlareLocation(LensFlareRay, 100.0f);
    float BlueDistance = distance(gl_TexCoord[0].st, BlueLocation);
    float BlueStrength = 1.0f / (1.0f + 10000.0f * BlueDistance);
    return vec3(0.0f, 0.0f, 1.0f) * BlueStrength; 
}

#endif