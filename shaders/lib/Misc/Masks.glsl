#ifndef MISC_MASKS_GLSL
#define MISC_MASKS_GLSL 1

#include "BlockID.glsl"

struct MaskStruct {
    bool Sky;
    bool Plant;
    bool LightSource;
    bool Sun;
};

#define SKY_BIT   1
#define PLANT_BIT 2
#define LIGHT_SOURCE_BIT 4
#define SUN_BIT 8

MaskStruct ConstructMaskStruct(in float id, in float torch){
    MaskStruct Masks;
    Masks.Sky = false;
    Masks.Plant = IS_TALL_GRASS(id);
    Masks.LightSource = (torch == 1.0f);
    Masks.Sun = false;
    return Masks;
}

#endif