# CIS 566 Project 1: Noisy Planets

## Live Demo: https://eddieh80.github.io/hw01-noisy-planet/

###Earth:
![](Earth.png)

###Molten:
![](Molten.png)

###Ice:
![](Ice.png)

###Starburst:
![](Starburst.png)

##Project Description:

The four biomes on the Earth are mountain, forest, beach, and ocean. The toolbox functions I used are sin/cos, bias, gain, and pulse. The GUI additions I made were a slider to change the planet, a slider to change the multiplier of the noise input, a slider to change the animation speed, and sliders to rotate the light source around if the planet has a shader model. 

###Earth:

I used FBM to create the general terrain and then added in Perlin Noise to create the mountains and Worley Noise to add more texture to the forests/sand. In the fragment shader I clamped the colors for the different biomes based on FBM and also used gain and bias to help transition between the colors. I used Blinn-Phong shading for this planet.

###Molten:

I used FBM with a higher scaled noise input to create the general terrain, and then spiked up the mountains by increasing the multiplier if a certain threshold was met and also decreased the multiplier and added animation if the noise value is below a certain threshold. I then fed in the same noise input into the fragment shader and used a cosine color palette to color in the terrain. I also used Blinn-Phong shading with a specular color that is tinted red to color the planet.

###Ice:

I fed in FBM with some constant modifiers into Perlin Noise, and then multiplied that into the input to FBM once again to create the terrain. I also used a threshold to modify some constants in order to create the ocean. I then fed in the same noise input into the fragment shader and used a cosine color palette to color in the terrain. I did not use any shading on this planet.

###Starburst:

I used FBM with some constant multipliers to create the general terrain and then to create the spikey inside I multiplied in Perlin Noise if a certain threshold was met. I then fed in the cosine of the time variable into a cubic pulse function to add animation. I once again used a cosine color palette add in the colors. I did not use any shading on this planet.
