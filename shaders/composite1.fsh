#version 120

const bool colortex0MipmapEnabled = true;

#include "lib/Blur/BloomTile.glsl"

void main() {
    vec3 Bloom = ComputeBloomTiles();
    /* DRAWBUFFERS:0 */
    gl_FragData[0].rgb = Bloom;
}