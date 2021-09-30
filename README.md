# HW 0: Noisy Planet Part 2
Name: Benjamin Sei
pennkey: bensei
External Resources:
https://iquilezles.org/
https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

This is a rotating planet. There are 4 biomes, whose locations are based on two noise functions and thresholding, the noise functions specifying to an extent the hotness and dryness. The terrain of the biomes is generated by various combinations of simplex noise, perlin noise, and fbm. The colors of these biomes use cosine color palettes and bis/gain functions the represent this. Lambert shading and Blinn-Phong was implemented (but the specular highlight is always present). Planet roates over time using trig functions, as well as the light vector. In the gui, you can modify the dryness and hotness thresholds to modify how much (or little) a biome shows up. You can also modify how many octaves the fbm noise functions use. 

Here is the live demo: https://ben-nin.github.io/hw00-webgl-intro/ 