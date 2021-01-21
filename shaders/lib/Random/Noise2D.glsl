#ifndef RANDOM_NOISE_2D_GLSL
#define RANDOM_NOISE_2D_GLSL 1

#include "Noise1D.glsl"

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
float GenerateNoise2D_0(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 CreateRandomRotation(in vec2 texcoord){
	float Rotation = texture2D(noisetex, texcoord).r;
	Rotation = (4.71238898038f * (2.0f * Rotation - 1.0f));
	float cosTheta = cos(Rotation);
	float sinTheta = sin(Rotation);
	return mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
}

mat2 CreateRandomRotationScreen(in vec2 texcoord){
	return CreateRandomRotation(texcoord * vec2(viewWidth / noiseTextureResolution, viewHeight / noiseTextureResolution));
}

//	Classic Perlin 2D Noise 
//	by Stefan Gustavson
//
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
vec4 permute2d(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}

float GenerateNoise2D_1(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute2d(permute2d(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

const int firstOctave = 3;
const int octaves = 8;
const float persistence = 0.6;

//Not able to use bit operator like <<, so use alternative noise function from YoYo
//
//https://www.shadertoy.com/view/Mls3RS
//
//And it is a better realization I think
float noise(int x,int y)
{   
    float fx = float(x);
    float fy = float(y);
    
    return 2.0 * fract(sin(dot(vec2(fx, fy) ,vec2(12.9898,78.233))) * 43758.5453) - 1.0;
}

float smoothNoise(int x,int y)
{
    return noise(x,y)/4.0+(noise(x+1,y)+noise(x-1,y)+noise(x,y+1)+noise(x,y-1))/8.0+(noise(x+1,y+1)+noise(x+1,y-1)+noise(x-1,y+1)+noise(x-1,y-1))/16.0;
}

float COSInterpolation(float x,float y,float n)
{
    float r = n*3.1415926;
    float f = (1.0-cos(r))*0.5;
    return x*(1.0-f)+y*f;
    
}

float InterpolationNoise(float x, float y)
{
    int ix = int(x);
    int iy = int(y);
    float fracx = x-float(int(x));
    float fracy = y-float(int(y));
    
    float v1 = smoothNoise(ix,iy);
    float v2 = smoothNoise(ix+1,iy);
    float v3 = smoothNoise(ix,iy+1);
    float v4 = smoothNoise(ix+1,iy+1);
    
   	float i1 = COSInterpolation(v1,v2,fracx);
    float i2 = COSInterpolation(v3,v4,fracx);
    
    return COSInterpolation(i1,i2,fracy);
    
}

float GenerateNoise2D_2(float x,float y)
{
    float sum = 0.0;
    float frequency =0.0;
    float amplitude = 0.0;
    for(int i=firstOctave;i<octaves + firstOctave;i++)
    {
        frequency = pow(2.0,float(i));
        amplitude = pow(persistence,float(i));
        sum = sum + InterpolationNoise(x*frequency,y*frequency)*amplitude;
    }
    
    return sum;
}

float GenerateNoise2D_2(vec2 coords){
	return GenerateNoise2D_2(coords.x, coords.y);
}


// https://www.shadertoy.com/view/MdScDc
//http://flafla2.github.io/2014/08/09/perlinnoise.html
//https://web.archive.org/web/20160530124230
//http://freespace.virgin.net/hugo.elias/models/m_perlin.htm
//http://eastfarthing.com/blog/2015-04-21-noise/
//https://www.youtube.com/watch?v=Or19ilef4wE
//https://www.youtube.com/watch?v=MJ3bvCkHJtE

//hash from iq
//https://www.shadertoy.com/view/Xs23D3
vec2 hash_iq( vec2 p ) 
{  						
	p = vec2(dot(p,vec2(127.1,311.7)),
			 dot(p,vec2(269.5,183.3)));
    
	return -1.0 + 2.0 * fract(sin(p + 20.0) * 53758.5453123);
}

float lerp(float a, float b, float t)
{
	return a + t * (b - a);
}

float perlin_noise_2(in vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
    
    //grid points
    vec2 p0 = vec2(0.0, 0.0);
    vec2 p1 = vec2(1.0, 0.0);
    vec2 p2 = vec2(0.0, 1.0);
    vec2 p3 = vec2(1.0, 1.0);
    
    //distance vectors to each grid point
    vec2 s0 = f - p0;
    vec2 s1 = f - p1;
    vec2 s2 = f - p2;
    vec2 s3 = f - p3;
    
    //random gradient vectors on each grid point
    vec2 g0 = hash_iq(i + p0);
    vec2 g1 = hash_iq(i + p1);
    vec2 g2 = hash_iq(i + p2);
    vec2 g3 = hash_iq(i + p3);
    
    //gradient values
    float q0 = dot(s0, g0);
    float q1 = dot(s1, g1);
    float q2 = dot(s2, g2);
    float q3 = dot(s3, g3);
    
    //interpolant weights
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    //bilinear interpolation
    float l0 = lerp(q0, q1, u.x);
    float l1 = lerp(q2, q3, u.x);
    float l2 = lerp(l0, l1, u.y);
    
    return l2;
}

float GenerateNoise2D_3(vec2 uv, float persistence = 0.7f, int octaves = 8) 
{
    float total = 0.0;
    float maxValue = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for(int i=0; i<octaves;++i)
    {
        total += perlin_noise_2(uv * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    
    return clamp(total/maxValue, 0.0f, 1.0f);
}

float GenerateNoise2D_4(in vec2 p){
	//p = fract(p);
	return texture2D(noisetex, p.xy * 0.1f).r;
}

float GenerateNoise2D_5(in vec2 p){
    float Octaves[4];
    Octaves[0] = GenerateNoise2D_4(p * -2.00f  ) * 0.125f;
    Octaves[1] = GenerateNoise2D_4(p *  2.00f  ) * 0.125f;
    Octaves[2] = GenerateNoise2D_4(p *  0.10f  ) * 0.250f;
    Octaves[3] = GenerateNoise2D_4(p * -0.10f  ) * 0.500f;
    return Octaves[0] + Octaves[1] + Octaves[2] + Octaves[3];
}

#endif