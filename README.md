# CIS 566 Project 1: Noisy Planets

## Info
- Lanqing Bao (lanqing)

## Result
# Terrain Generation
- Main func: float terrain_generate(vec3 p) in vertex shader, calculate continent noise, ridged fractal noise, and mask for mountain.
- 3D Simplex noise based FBM generated terrain with ocean & land. Noise parameters are all adjustable in dat.gui
- Mountain generated using ridge noise, parameters in Noise Control - Ridge.
- 3D Simplex noise based Mountain Mask to maintain ocean while having mountains.

- Ray-trace based ocean color
- Blinn-Phong + lambert shade
- Load Textrue on terrain (press Set Text then Load Scene)
- Cos-wave palette specular color
- Bias-based color blending different types of terrain
- 

## Citation 
- How to implement ray sphere casting https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d

## Submission
Commit and push to Github, then __make a pull request on the original Github repository__. Assignments will no longer be submitted on Canvas.

For this assignment, and for all future assignments, modify this README file
so that it contains the following information:
- Your name and PennKey
- Citation of any external resources you found helpful when implementing this
assignment.
- A link to your live github.io demo
- At least one screenshot of your planet
- An explanation of the techniques you used to generate your planet features.
Please be as detailed as you can; not only will this help you explain your work
to recruiters, but it helps us understand your project when we grade it!
