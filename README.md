# MinecraftShaders
My minecraft shaders for minecraft
# TODO List
TODO list:
- ~~Add forward rendering for gbuffers_water and other forward shader stages~~ 
- ~~Improve shadows while optimially keeping shadowDistance around 128.0f and shadowResolution under 2048~~
- Add other programs - partially done
- Organize the shader files in a better manner
- Specular map (labpbr)
- Add better support for plants (subsurface scattering and waving plants)
- Sky rendering (volumetric clouds and atmospheric scattering, ozone absorption ) - partially done
- Bloom
- DOF 
- SSAO
- SSR
- Reflective shadow maps
- Revisit volumetric lighting and try to implement it properly
- Give the shader a name
- 2D clouds, like the one in void 2.0 and seus v10.1
- Water droplet effect on the camera
- Use a LUT for atmospheric scattering
# Known issues
- Atmosphere looks bad and isn't completely physically based
- Translucent items do not have proper forward rendering when dropped
- Shadows of translucent items do not appear when held in the players hand
- Shadow acne at the bottom of the shadow map due to shadow distortion
- Volumetric lighting has an unintended cloud layer above the player
- VL also is barely visible in small scenes and maybe a bit too much in large scenes
- There is no fog for parts of the world behind the player due to the forward mie scattering that takes place in VL