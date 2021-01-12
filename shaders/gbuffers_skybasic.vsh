#version 120

#include "lib/Utility/Packing.glsl"

flat varying float fMasks;

void main(){
    MaskStruct Masks;
    Masks.Sky = true;
    Masks.Plant = false;
    Masks.LightSource = false;
    Masks.Sun = false;
    Masks.Hand = false;
    fMasks = CompressMaskStruct(Masks);
    gl_Position = ftransform();
    gl_Position = vec4(0.0f);
    //gl_FrontColor.a = 1.0f;
}