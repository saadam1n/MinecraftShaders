#ifndef UTILITY_PACKING_GLSL
#define UTILITY_PACKING_GLSL

#extension GL_EXT_gpu_shader4 : enable

#include "../Misc/Masks.glsl"

int PackMask(bool mask, const int bit){
    return (mask ? bit : 0);
}

bool UnpackMask(int ival, const int bit){
    return bool(ival & bit);
}

bool UnpackMask(float fval, const int bit){
    return bool(int(fval * 65535.0f) & bit);
}

float CompressMaskStruct(in MaskStruct masks){
    int imasks = 0;
    imasks |= PackMask(masks.Sky,   SKY_BIT  );
    imasks |= PackMask(masks.Plant, PLANT_BIT);
    imasks |= PackMask(masks.LightSource, LIGHT_SOURCE_BIT);
    imasks |= PackMask(masks.Sun, SUN_BIT);
    imasks |= PackMask(masks.Hand, HAND_BIT);
    float fmasks = float(imasks) / 65535.0f;
    return fmasks;
}

MaskStruct DecompressMaskStruct(in float fmasks){
    int imasks = int(fmasks * 65535.0f);
    MaskStruct UnpackedMasks;
    UnpackedMasks.Sky   = UnpackMask(imasks, SKY_BIT);
    UnpackedMasks.Plant = UnpackMask(imasks, PLANT_BIT);
    UnpackedMasks.LightSource = UnpackMask(imasks, LIGHT_SOURCE_BIT);
    UnpackedMasks.Sun = UnpackMask(imasks, SUN_BIT);
    UnpackedMasks.Hand = UnpackMask(imasks, HAND_BIT);
    return UnpackedMasks;
}

#endif