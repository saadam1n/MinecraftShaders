# MinecraftShaders
My minecraft shaders for minecraft
# TODO List
TODO list:
- ~~Add forward rendering for gbuffers_water and other forward shader stages~~ 
- ~~Improve shadows while optimially keeping shadowDistance around 128.0f and shadowResolution under 2048~~
- Add other programs - partially done
- Specular map (labpbr)
- Add better support for plants (subsurface scattering and waving plants)
- Sky rendering (volumetric clouds and atmospheric scattering, ozone absorption ) - partially done
- Bloom
- DOF 
- SSAO
- SSR
- Reflective shadow maps
# Known issues
- Atmosphere looks bad and isn't completely physically based
- Translucent items do not have proper forward rendering when dropped
- Shadows of translucent items do not appear when held in the players hand
- Shadow acne at the bottom of the shadow map due to shadow distortion