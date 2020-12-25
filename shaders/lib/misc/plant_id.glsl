#ifndef MISC_PLANT_ID_GLSL
#define MISC_PLANT_ID_GLSL 1

bool IsGrass(in float entity){
    return entity == 31.0f;
}

bool IsLeaves(in float entity){
    return false; // For now
}

bool IsPlant(in float id){
    return IsGrass(id) || IsLeaves(id);
}

#endif