# CIS 566 Project 1: Noisy Planets

## Submission Details
Name: Nathaniel Korzekwa
PennKey: korzekwa
Live Demo Link: 
<p align="center">
  <img src="https://user-images.githubusercontent.com/6472567/135378051-2bb5ccea-48e9-4302-b683-3ae11593640c.png">
</p>
<p align="center">Planet Angle 1</p>

<p align="center">
  <img src="https://user-images.githubusercontent.com/6472567/135378046-0cac887b-1d09-4106-badd-86cccf5c6aed.png">
</p>
<p align="center">Planet Angle 2</p>
[Live Demo](https://ciscprocess.github.io/hw01-noisy-planet/)

### Algorithm Descriptions
The planet is formed first with one main 3D Perlin noise function with fBM, normalized to a range of [0, 1] an 4 rounds of composition. Cutoff values that define the biome are then decided by the following uniform variables:
- `u_GrassCutoff`: If the main noise function is above this value at the given point, then render the point with a grass color pallette and with deformed normals. Below, render as ocean (see below).
- `u_MountainCutoff`: If the main noise functino is above this value, render with the mountain color pallete. ADDITIONALLY, note that the mountains have some green texturing, attempting to simulate moss, on sides with normals pointing to the left. This is achieved by dotting the normal vector with the left world vector, and coloring based on a threshold.
- `u_ForestCutoff`: If the mountain threshold is not met, then another noise function, AVERAGED with the main noise function is calculated. If this passes the threshold defined here, and the threshold listed below is passed, the terrain is rendered as forest. 
- `u_MountainSpacing`: This requires that for a point to be rendered as "forest", then the main noise function must be at least this amount BELOW the mountain cutoff. This is to prevent forests from spawning in the middle of mountain ranges, creating ugly boundaries.

The main terrain and mountain areas are colored by a single cosine color palette containing a range from green, brownish, to gray. Normals and Blinn-Phong shading give a shiny texture. Forests are colored with a darker forest palette and have simple white noise applied. I wish I could have done a better job with this, but there was no time. Note that normals are not as sharp on forests: I averaged the deformed normals with the originals to simulate the dampening effect trees may have on the terrains ridges.

The ocean is probably the most compelling part of this tiny planet: It is generated with a largely blue, but with a little green at higher bands, color palette in conjucntion with warped perlin noise: 3 perlin noise samples are collected at the given point and then are used to offset the point being input into another perlin noise function. This provides the marble-like texture. Then, a gain function is used before feeding to the color palette to push the exremeties to the edge of the planet, providing a semi-transparent, marble-like look. Finally, the look vector is factored into the color palette (via dot product with ocean surface normal) to provide iridescence. The ocean is animated by pushing the perlin noise input through the Z-axis over time.


### Sources
- [Noise Functions](https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83)
- [Bad Noise Function](https://stackoverflow.com/a/28095165)

## Objective
- Continue practicing WebGL and Typescript
- Experiment with noise functions to procedurally generate the surface of a planet
- Review surface reflection models

## Base Code
You'll be using the same base code as in homework 0.

## Assignment Details
- Update the basic scene from your homework 0 implementation so that it renders
an icosphere once again. We recommend increasing the icosphere's subdivision
level to 6 so you have more vertices with which to work.
- Write a new GLSL shader program that incorporates various noise functions and
noise function permutations to offset the vertices on the surface of the icosphere and modify the color of the icosphere so that it looks like a planet with geographic
features. Your planet should have __at least four distinct "biomes"__ on its surface (they do not have to be Earth biomes). Try making formations like mountain ranges, oceans, rivers, lakes, canyons, volcanoes, ice caps, glaciers, or even forests. We recommend using 3D noise functions whenever possible so that you don't have UV distortion, though that effect may be desirable if you're trying to make the poles of your planet stand out more.
- Combined with your noise functions, use __at least four__ different functions from the Toolbox Functions slides. They should be used to either adjust your noise distribution, or animate elements on your planet's surface.
- Implement __at least two__ surface reflection model (e.g. Lambertian, Blinn-Phong,
Matcap/Lit Sphere, Raytraced Specular Reflection) besides on the planet's surface to
better distinguish the different formations (and perhaps even biomes) on the
surface of your planet. Make sure your planet has a "day" side and a "night"
side; you could even place small illuminated areas on the night side to
represent cities lit up at night.
- Add GUI elements via dat.GUI that allow the user to modify different
attributes of your planet. This can be as simple as changing the relative
location of the sun to as complex as redistributing biomes based on overall
planet temperature. You should have __at least three modifiable attributes__.
- Have fun experimenting with different features on your planet. If you want,
you can even try making multiple planets! Your score on this assignment is in
part dependent on how interesting you make your planet, so try to
experiment with as much as you can!

Here are some examples of procedural planets:
- [Pixel Planet](https://deep-fold.itch.io/pixel-planet-generator)
- [Earthlike Planet](https://www.reddit.com/r/proceduralgeneration/comments/fqk56t/animation_procedural_planet_composition/)
- [Topographic Field](https://www.shadertoy.com/view/llscW7)
- [Dan's Final Project](https://vimeo.com/216265946)

## Useful Links
- [Implicit Procedural Planet Generation](https://static1.squarespace.com/static/58a1bc3c3e00be6bfe6c228c/t/58a4d25146c3c4233fb15cc2/1487196929690/ImplicitProceduralPlanetGeneration-Report.pdf)
- [Curl Noise](https://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html)
- [GPU Gems Chapter on Perlin Noise](http://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch05.html)
- [Worley Noise Implementations](https://thebookofshaders.com/12/)


## Submission
Commit and push to Github, then __make a pull request on the original Github repository__. Assignments will no longer be submitted on Canvas.

For this assignment, and for all future assignments, modify this README file
so that it contains the following information:
- Your name and PennKey
- Citation of any external resources you found helpful when implementing this assignment.
- A link to your live github.io demo
- At least one screenshot of your planet
- An explanation of the techniques you used to generate your planet features.
Please be as detailed as you can; not only will this help you explain your work
to recruiters, but it helps us understand your project when we grade it!

## Extra Credit
Any or All of the following bonus items:
- Use a 4D noise function to modify the terrain over time, where time is the
fourth dimension that is updated each frame. A 3D function will work, too, but
the change in noise will look more "directional" than if you use 4D.
- Use music to animate aspects of your planet's terrain (e.g. mountain height,
  brightness of emissive areas, water levels, etc.)
- Create a background for your planet using a raytraced sky box that includes
things like the sun, stars, or even nebulae.
- Add a textured moon that orbits your planet
