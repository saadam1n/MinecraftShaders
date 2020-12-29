#ifndef MISC_BLOCK_ID_GLSL
#define MISC_BLOCK_ID_GLSL 1

#define IS_BLOCK_ID(entity, id) (entity == id)

#define IS_LEAVES(entity) IS_BLOCK_ID(entity, 18.0f)
#define IS_TALL_GRASS(entity) IS_BLOCK_ID(entity, 31.0f)
#define IS_FIRE(entity) IS_BLOCK_ID(entity, 51.0f)

#endif