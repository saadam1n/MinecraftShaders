#version 120

const bool colortex0MipmapEnabled = true;

#include "lib/Utility/Uniforms.glsl"
#include "lib/Utility/Functions.glsl"
#include "lib/Effect/BloomTile.glsl"

// First create the bloom tiles

void main() {
    vec3 BloomTile = CreateBloomTiles();
    /* DRAWBUFFERS:1 */
    gl_FragData[0] = vec4(BloomTile, 1.0f);
}