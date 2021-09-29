# CIS 566 Project 1: Noisy Planets

## Project Description

Name: Amelia Peng PennKey: pqy

External resources: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83 https://learnopengl.com/Lighting/Basic-Lighting

Live demo: https://ameliapqy.github.io/hw00-webgl-intro/

Screenshot: ![planet](planet.jpg)

Techniques:

- fbm warp for planet texture
- adding sin waves of time on to the fbm function implementation to make the planet texture shift through time
- set threshold values and color palette to make planet biomes
- used ease in, mix, and smoothstep to blend the planet colors with different biomes
- used bias and gain for the pulsing feature and made planet pulse to become a sphere
-

## Objective

- Continue practicing WebGL and Typescript
- Experiment with noise functions to procedurally generate the surface of a planet
- Review surface reflection models

## Base Code

You'll be using the same base code as in homework 0.

## Assignment Details

- Update the basic scene from your homework 0 implementation so that it renders an icosphere once again. We recommend increasing the icosphere's subdivision level to 6 so you have more vertices with which to work.
- Write a new GLSL shader program that incorporates various noise functions and noise function permutations to offset the vertices on the surface of the icosphere and modify the color of the icosphere so that it looks like a planet with geographic features. Your planet should have **at least four distinct "biomes"** on its surface (they do not have to be Earth biomes). Try making formations like mountain ranges, oceans, rivers, lakes, canyons, volcanoes, ice caps, glaciers, or even forests. We recommend using 3D noise functions whenever possible so that you don't have UV distortion, though that effect may be desirable if you're trying to make the poles of your planet stand out more.
- Combined with your noise functions, use **at least four** different functions from the Toolbox Functions slides. They should be used to either adjust your noise distribution, or animate elements on your planet's surface.
- Implement **at least two** surface reflection model (e.g. Lambertian, Blinn-Phong, Matcap/Lit Sphere, Raytraced Specular Reflection) besides on the planet's surface to better distinguish the different formations (and perhaps even biomes) on the surface of your planet. Make sure your planet has a "day" side and a "night" side; you could even place small illuminated areas on the night side to represent cities lit up at night.
- Add GUI elements via dat.GUI that allow the user to modify different attributes of your planet. This can be as simple as changing the relative location of the sun to as complex as redistributing biomes based on overall planet temperature. You should have **at least three modifiable attributes**.
- Have fun experimenting with different features on your planet. If you want, you can even try making multiple planets! Your score on this assignment is in part dependent on how interesting you make your planet, so try to experiment with as much as you can!

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

Commit and push to Github, then **make a pull request on the original Github repository**. Assignments will no longer be submitted on Canvas.

For this assignment, and for all future assignments, modify this README file so that it contains the following information:

- Your name and PennKey
- Citation of any external resources you found helpful when implementing this assignment.
- A link to your live github.io demo
- At least one screenshot of your planet
- An explanation of the techniques you used to generate your planet features. Please be as detailed as you can; not only will this help you explain your work to recruiters, but it helps us understand your project when we grade it!

## Extra Credit

Any or All of the following bonus items:

- Use a 4D noise function to modify the terrain over time, where time is the fourth dimension that is updated each frame. A 3D function will work, too, but the change in noise will look more "directional" than if you use 4D.
- Use music to animate aspects of your planet's terrain (e.g. mountain height, brightness of emissive areas, water levels, etc.)
- Create a background for your planet using a raytraced sky box that includes things like the sun, stars, or even nebulae.
- Add a textured moon that orbits your planet
