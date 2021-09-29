# CIS 566 Project 1: Noisy Planets

## Info
- Lanqing Bao (lanqing)
- Link: https://seiseiko.github.io/hw01-noisy-planet/
# Result
## Terrain Generation
- Main func: float terrain_generate(vec3 p) in vertex shader, calculate continent noise, ridged fractal noise, and mask for mountain.
- 3D Simplex noise based FBM generated terrain with ocean & land. Noise parameters are all adjustable in dat.gui
- Mountain generated using ridged noise(with gain), parameters in Noise Control - Ridge. 
- 3D Simplex noise based Mountain Mask to maintain ocean while having mountains.
- SmoothStep blending ocean & land

## Surface Reflection & Shading
- Ray-trace based ocean color
- Blinn-Phong + lambert shading
- Load Textrue on terrain (press Set Text then Load Scene)
- Cos-wave palette specular color
- Bias-based color blending different types of terrain(ocean,shores,land,mountain)

## Controls
- All noise parameters are controllable
- Ocean parameters
- Sun position 
- Load texture(press Set Text then Load Scene)
## Screenshots

![](4.gif)
![](3.gif)
![](1.gif)

![](2.gif)

## Citation 
- How to implement ray sphere casting https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d
- Shading https://learnopengl.com/Advanced-Lighting/Advanced-Lighting
- Creating Planets in Unity https://www.youtube.com/watch?v=lctXaT9pxA0&t=1151s
