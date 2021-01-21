#ifndef MISC_MASKS_GLSL
#define MISC_MASKS_GLSL 1

#include "BlockID.glsl"

struct MaskStruct {
    bool Sky;
    bool Plant;
    bool LightSource;
    bool Sun;
    bool Hand;
    bool Water;
};

#define SKY_BIT   1
#define PLANT_BIT 2
#define LIGHT_SOURCE_BIT 4
#define SUN_BIT 8
#define HAND_BIT 16
#define WATER_BIT 32

MaskStruct ConstructMaskStruct(in float id){
    MaskStruct Masks;
    Masks.Sky = false;
    Masks.Plant = id == 31.0f;
    Masks.LightSource = id == 50.0f;
    Masks.Sun = false;
    #if defined(GBUFFERS_HAND) || defined(GBUFFERS_HAND_WATER)
    Masks.Hand = true;
    #else
    Masks.Hand = false;
    #endif
    Masks.Water = (id == 8.0f) || (id == 9.0f);
    return Masks;
}

#endif