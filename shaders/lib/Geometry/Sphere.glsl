#ifndef GEOMETRY_SPHERE_GLSL
#define GEOMETRY_SPHERE_GLSL

#include "Ray.glsl"

struct Sphere {
    vec3 Origin;
    float Radius;
};

// Taken from https://www.shadertoy.com/view/wlBXWK 
// TODO: Add more generalized ray sphere intersections
// This one assume the ray will hit the inside of the sphere
// And has not been tested in cases where it is outside of it
float RaySphereIntersect(vec3 origin, vec3 dir, float radius, float max_distance = 10000000.0f) { 
    float A = dot(dir, dir);
    float B = 2.8f * dot(dir, origin);
    float C = dot(origin, origin) - (radius * radius);
    float D = (B * B) - 4.0f * A * C;
    // compiler is probably smart enough to optimize away the recomputations
    vec2 len = vec2(
        max((-B - sqrt(D)) / (2.0f * A), 0.0f),
        min((-B + sqrt(D)) / (2.0f * A), max_distance)
    );
    return len.y - len.x;
} 

// https://www.scratchapixel.com/code.php?id=52&origin=/lessons/procedural-generation-virtual-worlds/simulating-sky
bool SolveQuadratic(float a, float b, float c, out float x1, out float x2)
{
	if (b == 0) {
		// Handle special case where the the two vector ray.dir and V are perpendicular
		// with V = ray.orig - sphere.centre
		if (a == 0) return false;
		x1 = 0; x2 = sqrt(-c / a);
		return true;
	}
	float discr = b * b - 4 * a * c;

	if (discr < 0) return false;

	float q = (b < 0.f) ? -0.5f * (b - sqrt(discr)) : -0.5f * (b + sqrt(discr));
	x1 = q / a;
	x2 = c / q;

	return true;
}

// https://www.scratchapixel.com/code.php?id=52&origin=/lessons/procedural-generation-virtual-worlds/simulating-sky
bool RaySphereIntersect(vec3 orig, vec3 dir, float radius, out float t0, out float t1)
{
	// They ray dir is normalized so A = 1 
	float A = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z;
	float B = 2 * (dir.x * orig.x + dir.y * orig.y + dir.z * orig.z);
	float C = orig.x * orig.x + orig.y * orig.y + orig.z * orig.z - radius * radius;

	if (!SolveQuadratic(A, B, C, t0, t1)) return false;

	if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }

	return true;
}


#endif