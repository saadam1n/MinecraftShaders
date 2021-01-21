#version 120

#include "lib/Utility/Uniforms.glsl"

#define LENS_FLARE_STARBURST

// https://www.reddit.com/r/gamedev/comments/20xyn4/heres_a_great_chromatic_aberration_glsl_function/
const vec3 ChromaticAberrationKernel[9] = vec3[9](
    vec3(0.0000000000000000000, 0.04416589065853191, 0.0922903086524308425), vec3(0.10497808951021347), vec3(0.0922903086524308425, 0.04416589065853191, 0.0000000000000000000),
    vec3(0.0112445223775533675, 0.10497808951021347, 0.1987116566428735725), vec3(0.40342407932501833), vec3(0.1987116566428735725, 0.10497808951021347, 0.0112445223775533675),
    vec3(0.0000000000000000000, 0.04416589065853191, 0.0922903086524308425), vec3(0.10497808951021347), vec3(0.0922903086524308425, 0.04416589065853191, 0.0000000000000000000)
); 

vec3 ComputeChromaticAberation0(void){
    // TODO: precompute offsets and use negation to compute other ones
    vec3 Color = vec3(0.0f);
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2(-1.0f,  1.0f) * TexelSize).rgb * ChromaticAberrationKernel[0];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 0.0f,  1.0f) * TexelSize).rgb * ChromaticAberrationKernel[1];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 1.0f,  1.0f) * TexelSize).rgb * ChromaticAberrationKernel[2];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2(-1.0f,  0.0f) * TexelSize).rgb * ChromaticAberrationKernel[3];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 0.0f,  0.0f) * TexelSize).rgb * ChromaticAberrationKernel[4];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 1.0f,  0.0f) * TexelSize).rgb * ChromaticAberrationKernel[5];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2(-1.0f, -1.0f) * TexelSize).rgb * ChromaticAberrationKernel[6];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 0.0f, -1.0f) * TexelSize).rgb * ChromaticAberrationKernel[7];
    Color += texture2D(colortex7, gl_TexCoord[0].st + vec2( 1.0f, -1.0f) * TexelSize).rgb * ChromaticAberrationKernel[8];
    return Color;
}

#define CHROMATIC_ABERATION_MULT 0.05 // [ 0.0 0.0125 0.025 0.05 0.075 0.1 0.15 0.2 0.25 0.3 0.4 0.5]

const vec3 ChromaticAberationStrength = (vec3(1.1f, 1.0f, 0.9f)-1.0f) * CHROMATIC_ABERATION_MULT;

vec2 ComputeChromaticAberationCoord(in vec2 CenterVec, in float Strenght){
    vec2 new_coord = gl_TexCoord[0].st + CenterVec * Strenght;
    // Make sure nothing goes out of bounds
    // Hopefully the user isn't looking at the edge of their screen
    bvec2 out_of_bounds = lessThan(new_coord, vec2(0.0f)) || greaterThan(new_coord, vec2(1.0f));
    if(any(out_of_bounds)){
        return gl_TexCoord[0].st;
    } else {
        return new_coord;
    }
}

/*
Basic idea:
Stretch out the texcoord away from the center
The farther away from the center, the stronger the stretch
How much it gets streched is deteremined by a wavelength-based (or in this case, a channel dependent) factor
This effect is insanely cheap but may be a little difficult to tune
*/
vec3 ComputeChromaticAberation1(void){
    vec2 CenterVec = gl_TexCoord[0].st - 0.5f;
    vec2 Coords[3];
    Coords[0] = ComputeChromaticAberationCoord(CenterVec, ChromaticAberationStrength.r);
    Coords[1] = ComputeChromaticAberationCoord(CenterVec, ChromaticAberationStrength.g);
    Coords[2] = ComputeChromaticAberationCoord(CenterVec, ChromaticAberationStrength.b);
    vec3 Color = vec3(0.0f);
    Color.r = texture2D(colortex7, Coords[0]).r;
    Color.g = texture2D(colortex7, Coords[1]).g;
    Color.b = texture2D(colortex7, Coords[2]).b;
    return Color;
}

float ViewOffset = gbufferModelView[2].z * fract(cameraPosition.x + cameraPosition.y + cameraPosition.z) * 0.1f;

void main(){
    vec3 LensFlare = clamp(texture2D(colortex3, gl_TexCoord[0].st).rgb, vec3(0.0f), vec3(100.0f)) * 0.3f;
    vec3 BaseColor = ComputeChromaticAberation1();
    #ifdef LENS_FLARE_STARBURST
    vec2 CenterVector = gl_TexCoord[0].st - 0.5;
    float Radial = acos(CenterVector.x / length(CenterVector));
    float StarBurst = texture2D(colortex6, vec2(Radial + ViewOffset, 0.0f)).r * texture2D(colortex6, vec2(Radial - ViewOffset * 0.5f, 0.0f)).r;
    LensFlare *= StarBurst;
    #endif
    /* DRAWBUFFERS:7 */
    gl_FragData[0].rgb = LensFlare + BaseColor;
}