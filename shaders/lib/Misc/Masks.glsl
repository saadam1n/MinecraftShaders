#ifndef MISC_MASKS_GLSL
#define MISC_MASKS_GLSL 1

#include "BlockID.glsl"

struct MaskStruct {
    bool Sky;
    bool Plant;
};

#define SKY_BIT   1
#define PLANT_BIT 2

MaskStruct ConstructMaskStruct(in float id){
    MaskStruct Masks;
    Masks.Sky = false;
    Masks.Plant = IS_TALL_GRASS(id);
    return Masks;
}

#endif