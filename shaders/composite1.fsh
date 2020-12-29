#version 120

const bool colortex0MipmapEnabled = false;

#include "lib/Blur/BloomTile.glsl"

void main() {
    vec3 Bloom = ComputeBloomTiles();
    /* DRAWBUFFERS:0 */
    gl_FragData[0].rgb = Bloom;
}