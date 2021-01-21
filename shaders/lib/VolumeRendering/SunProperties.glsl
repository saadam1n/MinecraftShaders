#ifndef VOLUME_RENDERING_SUN_PROPERTIES_GLSL
#define VOLUME_RENDERING_SUN_PROPERTIES_GLSL 1

/*
const float SunDistance = 147158715.0e3f;
const float SunRadius = 696340.0e3f;
const float SunSizeDegrees = 0.5f;
const float SunSizeRadians = radians(0.5f);
#if 1
const float SunSpotSize = cos(atan(SunRadius / SunDistance));
#else
const float SunSpotSize = cos(SunSizeRadians);
#endif
*/
const float SunSpotSize = cos(radians(3.5264000817029f));//cos(radians(0.5333f)); // Same value as void 2.0 dev

const float SunBrightness = 30.0f;
const vec3 SunColor = vec3(1.0f, 1.0f, 1.0f) * SunBrightness;
const float SunColorBrightness = 0.3f;

#endif