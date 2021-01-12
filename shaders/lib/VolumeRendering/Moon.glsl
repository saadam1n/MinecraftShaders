#ifndef VOLUMERENDERING_MOON_GLSL
#define VOLUMERENDERING_MOON_GLSL 1

const vec3 MoonColor = vec3(0.15f, 0.2f, 1.3f);
const vec3 MoonSkyColor = vec3(0.7f, 0.8f, 1.3f);

vec3 ComputeMoonColor(in vec3 view, in vec3 world){
    float cosTheta = dot(normalize(view), normalize(moonPosition));
    float cosTheta_unorm = cosTheta * 0.5f + 0.5f;
    float ForwardScatter = (0.5f + pow(cosTheta_unorm, 3.0f));
    float MoonGlow = (exp(pow(cosTheta_unorm, 100.0f)) - 1.0f) * 0.05f * ForwardScatter;
    const float Begin = 0.9986f;
    const float End = 0.9996f;
    // A solid color moon fits here batter, add noise if you want the moon to be textured
    float MoonStrength = (clamp(cosTheta, Begin, End) - Begin) / (End - Begin);
    vec3 MoonFogPos = 100.0f * world;
    //              Exp fog                                    Fog scale height trick                 Forward scatter phase approx
    float MoonFog = (1.0f - exp(-0.1f * length(MoonFogPos))) * exp(-max(MoonFogPos.y, 0.0f) / 7.0f) * ForwardScatter;
    float SkyDensity = pow(max(1.1f - world.y, 0.0f), 20.0f);
    vec3 SkyExtinction = exp(-SkyDensity * vec3(0.4f, 0.3f, 0.1f)) * SkyDensity;
    return MoonSkyColor * (smoothstep(0.0f, 1.0f, MoonStrength) * 3.0f + MoonGlow + MoonFog);
}

vec3 ComputeStarColor(vec3 world){
    //vec2 angles; // https://learnopengl.com/Getting-started/Camera
    //angles.x = acos(sqrt(abs(world.x))); // or  acos(world.z / world.y);
    //angles.y = asin(world.y);
    float blend = max(world.y, 0.0f);
    blend = blend * blend * blend;
    return vec3(mix(0.0f, step(texture2D(noisetex, world.xz * 0.407f).r, 0.02f), blend));
}

vec3 ComputeNightSky(in vec3 view, in vec3 world){
    vec3 Moon = ComputeMoonColor(view, world);
    vec3 Star = ComputeStarColor(world);
    return Moon + Star;
}

#endif