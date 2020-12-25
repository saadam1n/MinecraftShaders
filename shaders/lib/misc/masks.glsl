#ifndef MISC_MASKS_GLSL
#define MISC_MASKS_GLSL 1

#include "plant_id.glsl"

#extension GL_EXT_gpu_shader4 : enable

struct MaskStruct {
    bool Sky;
    bool Plant;
};

#define SKY_BIT   1
#define PLANT_BIT 2

int PackMask(bool mask, const int shift){
    int imask_val = int(mask);
    imask_val = imask_val >> shift;
    return imask_val;
}

bool UnpackMask(int ival, const int bit){
    return bool(ival & bit);
}

bool UnpackMask(float fval, const int bit){
    return bool(int(fval * 65535.0f) & bit);
}

float CompressMaskStruct(in MaskStruct masks){
    int imasks = 0;
    imasks = imasks & PackMask(masks.Sky,   0);
    imasks = imasks & PackMask(masks.Plant, 1);
    float fmasks = float(imasks) / 65535.0f;
    return fmasks;
}

MaskStruct DecompressMaskStruct(in float fmasks){
    int imasks = int(fmasks * 65535.0f);
    MaskStruct UnpackedMasks;
    UnpackedMasks.Sky   = UnpackMask(imasks, SKY_BIT);
    UnpackedMasks.Plant = UnpackMask(imasks, PLANT_BIT);
    return UnpackedMasks;
}

MaskStruct ConstructMaskStruct(in float id){
    MaskStruct Masks;
    Masks.Sky = false;
    Masks.Plant = IsPlant(id);
    return Masks;
}

#endif