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
- Fire volume rendering
# Known issues
- Atmosphere looks bad and isn't completely physically based
- Translucent items do not have proper forward rendering when dropped
- Shadows of translucent items do not appear when held in the players hand
- Shadow acne at the bottom of the shadow map due to shadow distortion
- Volumetric lighting has an unintended cloud layer above the player
- VL also is barely visible in small scenes and maybe a bit too much in large scenes
- There is no fog for parts of the world behind the player due to the forward mie scattering that takes place in VL
# Works used
This shader is based of the works of:
- Continuum Shader Tutorial
- Continuum Shaders
- SEUS V10.1
- KUDA V6.5.56
- [Scratch A Pixel - Simulating the Colors of the Sky](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/simulating-sky/simulating-colors-of-the-sky)
- [Oskar Elek - Rendering Parametrizable Planetary Atmospheres with Multiple Scattering in Real-Time](http://www.klayge.org/material/4_0/Atmospheric/Rendering%20Parametrizable%20Planetary%20Atmospheres%20with%20Multiple%20Scattering%20in%20Real-Time.pdf) 
- [Learn OpenGL - Bloom](https://learnopengl.com/Advanced-Lighting/Bloom)
- [labPBR Documentation](https://github.com/rre36/lab-pbr/wiki)