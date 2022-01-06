#version 300 es
precision highp float;
precision highp int;

uniform int u_Time;
uniform float u_Seed;
uniform float u_GrassCutoff;
uniform float u_MountainCutoff;
uniform float u_ForestCutoff;
uniform float u_NormDifferential;
uniform float u_MountainSpacing;
uniform bool u_AnalyticNorm;
uniform float u_MountainGrassCutoff;


// Noise function candidate 1 (based on golden ratio)
// From: https://stackoverflow.com/a/28095165
const float PHI = 1.61803398874989484820459;
float randomNoise1(in vec3 xyz, in float seed) {
    return fract(sin(distance(xyz * PHI, xyz)) * xyz.x);
}

float randomNoise2(vec3 p, float seed) {
    return fract(sin(dot(p, vec3(12.9898, -78.233, 133.999)))  * (43758.5453 + seed));
}

float randomNoise3(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float randomNoise3(vec3 co){
    float noise = randomNoise3(co.xy);
    return randomNoise3(vec2(noise, co.z));
}

float bias(float time, float bias) {
    return (time / ((((1.0 / bias) - 2.0) * (1.0 - time)) + 1.0));
}

float dbias(float t, float b) {
    return -b*(b - 1.) / pow(b*(2.*t - 1.) - t + 1., 2.);
}

float gain(float time, float gain) {
    if (time < 0.5) {
        return bias(time * 2.0, gain) / 2.0;
    } else {
        return bias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

vec3 getLatticeVector(vec3 p, float seed) {
    float x = -1.f + 2.f * randomNoise2(p, 1201.f + seed);
    float y = -1.f + 2.f * randomNoise2(p, 44402.f + seed);
    float z = -1.f + 2.f * randomNoise2(p, 23103.f + seed);

    return vec3(x, y, z);
}

float interpQuintic(float x, float a, float b) {
    float mod = 1.f - 6.f * pow(x, 5.f) + 15.f * pow(x, 4.f) - 10.f * pow(x, 3.f);
    return mix(a, b, 1.f - mod);
}

float interpQuintic3D(vec3 p, float bnl, float bnr, float bfr, float bfl, float tnl, float tnr, float tfr, float tfl) {
    vec3 base = floor(p);
    vec3 diff = p - base;

    float bl = interpQuintic(diff.z, bnl, bfl);
    float br = interpQuintic(diff.z, bnr, bfr);
    float tl = interpQuintic(diff.z, tnl, tfl);
    float tr = interpQuintic(diff.z, tnr, tfr);

    float l = interpQuintic(diff.y, bl, tl);
    float r = interpQuintic(diff.y, br, tr);

    return interpQuintic(diff.x, l, r);
}

const vec3 bnlv2 = vec3(0.f, 0.f, 0.f);
const vec3 bnrv2 = vec3(1.f, 0.f, 0.f);
const vec3 bfrv2 = vec3(1.f, 0.f, 1.f);
const vec3 bflv2 = vec3(0.f, 0.f, 1.f);
const vec3 tnlv2 = vec3(0.f, 1.f, 0.f);
const vec3 tnrv2 = vec3(1.f, 1.f, 0.f);
const vec3 tfrv2 = vec3(1.f, 1.f, 1.f);
const vec3 tflv2 = vec3(0.f, 1.f, 1.f);

const float sqrt3 = 1.732050807568877;
const float sqrt3d2 = 1.732050807568877 / 2.f;

vec4 perlin(vec3 p, float seed) {
    vec3 lp2 = floor(p);
    vec3 w = fract(p);
    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    vec3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    vec3 bnl = getLatticeVector(lp2 + bnlv2, seed);
    vec3 bnr = getLatticeVector(lp2 + bnrv2, seed);
    vec3 bfr = getLatticeVector(lp2 + bfrv2, seed);
    vec3 bfl = getLatticeVector(lp2 + bflv2, seed);
    vec3 tnl = getLatticeVector(lp2 + tnlv2, seed);
    vec3 tnr = getLatticeVector(lp2 + tnrv2, seed);
    vec3 tfr = getLatticeVector(lp2 + tfrv2, seed);
    vec3 tfl = getLatticeVector(lp2 + tflv2, seed);

    float dotBnl = dot(w, bnl);
    float dotBnr = dot(w - bnrv2, bnr);
    float dotBfr = dot(w - bfrv2, bfr);
    float dotBfl = dot(w - bflv2, bfl);

    float dotTnl = dot(w - tnlv2, tnl);
    float dotTnr = dot(w - tnrv2, tnr);
    float dotTfr = dot(w - tfrv2, tfr);
    float dotTfl = dot(w - tflv2, tfl);

    vec3 d = bnl +
             u.x * (bnr - bnl) +
             u.y * (tnl - bnl) +
             u.z * (bfl - bnl) +
             u.x * u.y * (bnl - bnr - tnl + tnr) +
             u.y * u.z * (bnl - tnl - bfl + tfl) +
             u.z * u.x * (bnl - bnr - bfl + bfr) +
             u.x * u.y * u.z * (-bnl + bnr + tnl - tnr + bfl - bfr - tfl + tfr) +

             du * (vec3(dotBnr - dotBnl, dotTnl - dotBnl, dotBfl - dotBnl) +
                   u.yzx * vec3(dotBnl - dotBnr - dotTnl + dotTnr, dotBnl - dotTnl - dotBfl + dotTfl, dotBnl - dotBnr - dotBfl + dotBfr) + 
                   u.zxy * vec3(dotBnl - dotBnr - dotBfl + dotBfr, dotBnl - dotBnr - dotTnl + dotTnr, dotBnl - dotTnl - dotBfl + dotTfl) + 
                   u.yzx * u.zxy * (-dotBnl + dotBnr + dotTnl - dotTnr + dotBfl - dotBfr - dotTfl + dotTfr));

    float bl = mix(dotBnl, dotBfl, u.z);
    float br = mix(dotBnr, dotBfr, u.z);
    float tl = mix(dotTnl, dotTfl, u.z);
    float tr = mix(dotTnr, dotTfr, u.z);

    float l = mix(bl, tl, u.y);
    float r = mix(br, tr, u.y);

    return vec4(sqrt3d2 + mix(l, r, u.x), d) / sqrt3;
}

vec4 fbmPerlin(vec3 p,   // The point in 3D space to get perlin value for
    float seed,           // Seed for perlin noise.
    int rounds,           // # of rounds of frequency summation/reconstruction
    float ampDecay,       // Amplitude decay per 'octave'.
    float freqGain) {     // Frequency gain per 'octave'.

    vec4 acc = vec4(0.);
    float amplitude = 1.f;
    float freq = 0.5f;
    float normC = 0.f;
    for (int round = 0; round < rounds; round++) {
        vec4 noise = amplitude * perlin(p * freq, u_Seed + seed);
        noise.yzw *= freq;
        acc += noise;
        normC += amplitude;
        amplitude *= ampDecay;
        freq *= freqGain;
    }

    return acc / normC;
}

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }
float noise(vec3 x, float seed) {
    vec3 step = vec3(110, seed, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);

    // For performance, compute the base input to a 1D hash from the integer part of the argument and the 
    // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbmValueNoise(vec3 p,   // The point in 3D space to get perlin value for
    float seed,               // Seed for the noise function.
    int rounds,               // # of rounds of frequency summation/reconstruction
    float ampDecay,           // Amplitude decay per 'octave'.
    float freqGain) {         // Frequency gain per 'octave'.

    float acc = 0.f;
    float amplitude = 1.f;
    float freq = 0.5f;
    float normC = 0.f;
    for (int round = 0; round < rounds; round++) {
        acc += amplitude * noise(p * freq, seed);
        normC += amplitude;
        amplitude *= ampDecay;
        freq *= freqGain;
    }

    return acc / normC;
}

float getMountainMembership(vec3 p) {
    return fbmPerlin(p / 0.5f, 24.f, 4, 0.6f, 2.f).x;
}

float getForestMembership(vec3 p) {
    return fbmPerlin(p / 0.5f, 55.f, 3, 0.6f, 3.f).x;
}

vec4 getGrassMembership(vec3 p) {
    vec4 noise = fbmPerlin(p * 5., 23.f, 4, 0.4f, 3.2f);
    noise.yzw *= 5.f;
    return noise;
}

const int WATER = 0;
const int MOUNTAIN = 1;
const int FOREST = 2;
const int GRASS = 3;
const int GRASS_MOUNTAIN = 4;

int getBiome(
    in vec3 p,
    out float mountain,
    out float forest,
    out float grass) {

    grass = getGrassMembership(p).x;
    forest = (grass + getForestMembership(p)) /  2.f;

    if (grass > u_MountainCutoff) {
        return MOUNTAIN;
    } else if (grass > u_GrassCutoff) {
        if (forest - grass > u_MountainSpacing && forest > u_ForestCutoff) {
            return FOREST;
        }

        if (grass > u_MountainCutoff - u_MountainGrassCutoff) {
            return GRASS_MOUNTAIN;
        }

        return GRASS;
    }

    mountain = getMountainMembership(p);

    return WATER;
}

float getWaterNoise(vec3 p) {
    return fbmPerlin(p / 0.5f, 999.f, 5, 0.6f, 3.f).x;
}

float getCloudNoise(vec3 p) {
    return fbmPerlin(p / 0.5f, 888.f, 8, 0.8,  1.5f).x;
}

vec4 terrainNoise(vec3 p) {
    vec4 grass = getGrassMembership(p);
    float f = clamp((grass.x - u_GrassCutoff) / (1.f - u_GrassCutoff), 0.f, 10.f);
    f = bias(f, 0.2f) * 0.5f;
    vec3 grad = ceil(f) * 0.5 * dbias(f, 0.2) * (grass.yzw / (1.f - u_GrassCutoff));
    return vec4(f, grad);
}

vec3 deformTerrain(vec3 p, vec4 noise) {
    float mod = noise.x;
    return p * (1.f + mod);
}

vec3 transformNormalAnalytic(vec3 p, vec4 noise, vec3 normal) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));
    float base = noise.x;
    float ddt = base + u_NormDifferential * dot(tangent, noise.yzw);
    float ddb = base + u_NormDifferential * dot(bitangent, noise.yzw);
    vec3 dp = p * (1.f + base);
    vec3 dt = (p + u_NormDifferential * tangent) * (1. + ddt);
    vec3 db = (p + u_NormDifferential * bitangent) * (1. + ddb);
    return normalize(cross(dp - db, dp - dt));
}

vec3 transformNormal(vec3 p, vec3 dp, vec3 normal) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));

    vec3 pt = p + u_NormDifferential * tangent;
    vec3 dt = deformTerrain(pt, terrainNoise(pt));
    vec3 pb = p + u_NormDifferential * bitangent;
    vec3 db = deformTerrain(pb, terrainNoise(pb));

    return normalize(cross(dp - db, dp - dt));
}