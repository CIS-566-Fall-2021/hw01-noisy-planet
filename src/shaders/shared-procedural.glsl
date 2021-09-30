#version 300 es
precision mediump float;
precision mediump int;

uniform int u_Time;
uniform float u_Seed;
uniform float u_GrassCutoff;
uniform float u_MountainCutoff;
uniform float u_ForestCutoff;
uniform float u_NormDifferential;
uniform float u_MountainSpacing;
uniform bool u_SymmetricNorm;
uniform float u_MountainGrassCutoff;


// Noise function candidate 1 (based on golden ratio)
// From: https://stackoverflow.com/a/28095165
const float PHI = 1.61803398874989484820459;
float randomNoise1(in vec3 xyz, in float seed) {
    return fract(tan(distance(xyz * PHI, xyz) * seed) * xyz.x);
}

float randomNoise2(vec3 p, float seed) {
    return fract(sin(dot(p, vec3(12.9898, -78.233, 133.999))) * (seed + 16.f));
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

float gain(float time, float gain) {
    if (time < 0.5) {
        return bias(time * 2.0, gain) / 2.0;
    } else {
        return bias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

vec3 normalizeNZ(vec3 v) {
    if (v.x == 0.f && v.y == 0.f && v.z == 0.f) {
        return v;
    } else {
        return v;//normalize(v);
    }
}

vec3 getLatticeVector(vec3 p, float cutoff, float seed) {
    float chance = randomNoise2(p, 1000.f + seed);
    if (chance > cutoff) {
        //return vec3(0.f, 0.f, 0.f);
    }

    float x = -1.f + 2.f * randomNoise1(p, 1201.f + seed);
    float y = -1.f + 2.f * randomNoise1(p, 44402.f + seed);
    float z = -1.f + 2.f * randomNoise1(p, 23103.f + seed);

    return normalizeNZ(vec3(x, y, z));
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

const vec3 bnlv = vec3(0.f, 0.f, 0.f);
const vec3 bnrv = vec3(1.f, 0.f, 0.f);
const vec3 bfrv = vec3(1.f, 0.f, 1.f);
const vec3 bflv = vec3(0.f, 0.f, 1.f);

const vec3 tnlv = vec3(0.f, 1.f, 0.f);
const vec3 tnrv = vec3(1.f, 1.f, 0.f);
const vec3 tfrv = vec3(1.f, 1.f, 1.f);
const vec3 tflv = vec3(0.f, 1.f, 1.f);
const float sqrt3 = 1.732050807568877;
float perlin(vec3 p, float voxelSize, float nonZeroCutoff, float seed) {
    p.x += 100.f;
    p.y += 100.f;
    p.z += 100.f;
    p /= voxelSize;
    vec3 lp = floor(p);

    vec3 bnl = getLatticeVector(lp + bnlv, nonZeroCutoff, seed);
    vec3 bnr = getLatticeVector(lp + bnrv, nonZeroCutoff, seed);
    vec3 bfr = getLatticeVector(lp + bfrv, nonZeroCutoff, seed);
    vec3 bfl = getLatticeVector(lp + bflv, nonZeroCutoff, seed);
    vec3 tnl = getLatticeVector(lp + tnlv, nonZeroCutoff, seed);
    vec3 tnr = getLatticeVector(lp + tnrv, nonZeroCutoff, seed);
    vec3 tfr = getLatticeVector(lp + tfrv, nonZeroCutoff, seed);
    vec3 tfl = getLatticeVector(lp + tflv, nonZeroCutoff, seed);

    float dotBnl = dot(normalizeNZ(p - lp), bnl);
    float dotBnr = dot(normalizeNZ(p - lp - bnrv), bnr);
    float dotBfr = dot(normalizeNZ(p - lp - bfrv), bfr);
    float dotBfl = dot(normalizeNZ(p - lp - bflv), bfl);

    float dotTnl = dot(normalizeNZ(p - lp - tnlv), tnl);
    float dotTnr = dot(normalizeNZ(p - lp - tnrv), tnr);
    float dotTfr = dot(normalizeNZ(p - lp - tfrv), tfr);
    float dotTfl = dot(normalizeNZ(p - lp - tflv), tfl);

    return (sqrt3/2.f + interpQuintic3D(p, dotBnl, dotBnr, dotBfr, dotBfl, dotTnl, dotTnr, dotTfr, dotTfl)) / sqrt3;
}

float fbmPerlin(vec3 p,   // The point in 3D space to get perlin value for
    float voxelSize,      // The size of each voxel in perlin lattice
    float nonZeroCutoff,  // The chance that a given lattice vector is nonzero
    float seed,           // Seed for perlin noise.
    int rounds,           // # of rounds of frequency summation/reconstruction
    float ampDecay,       // Amplitude decay per 'octave'.
    float freqGain) {     // Frequency gain per 'octave'.

    float acc = 0.f;
    float amplitude = 1.f;
    float freq = 0.5f;
    float normC = 0.f;
    for (int round = 0; round < rounds; round++) {
        acc += amplitude * perlin(p * freq, voxelSize, nonZeroCutoff, u_Seed + seed);
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

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise2(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
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

float fbmValueNoise2(vec3 p,   // The point in 3D space to get perlin value for
    float seed,               // Seed for the noise function.
    int rounds,               // # of rounds of frequency summation/reconstruction
    float ampDecay,           // Amplitude decay per 'octave'.
    float freqGain) {         // Frequency gain per 'octave'.

    float acc = 0.f;
    float amplitude = 1.f;
    float freq = 0.5f;
    float normC = 0.f;
    for (int round = 0; round < rounds; round++) {
        acc += amplitude * noise2(p * freq);
        normC += amplitude;
        amplitude *= ampDecay;
        freq *= freqGain;
    }

    return acc / normC;
}

vec3 colorWheel1(float angle) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.1);
    vec3 c = vec3(1, 1, 2);
    vec3 d = vec3(0, 0.25, 0.75);
    return a + b * cos(2.f * 3.14159 * (c * angle + d));
}

vec3 colorWheelForest(float angle) {
    vec3 a = vec3(0.f, 0.35, 0.f);
    vec3 b = vec3(0.f, 0.10, 0.f);
    vec3 c = vec3(0, 4.f, 0);
    vec3 d = vec3(0, 0.25, 0.75);
    return a + b * cos(2.f * 3.14159 * (c * angle + d));
}

vec3 colorWheelGrass(float angle) {
    vec3 a = vec3(0.f, 0.7, 0.f);
    vec3 b = vec3(0.f, 0.2, 0.f);
    vec3 c = vec3(0, 4.f, 0);
    vec3 d = vec3(0, 0.25, 0.0);
    return a + b * cos(2.f * 3.14159 * (c * angle + d));
}

vec3 colorWheelWater(float angle) {
    vec3 a = vec3(0.0, 0.2, 0.5);
    vec3 b = vec3(0.05, 0.2, 0.25);
    vec3 c = vec3(1, 1, 2);
    vec3 d = vec3(0, 0.25, 0.75);
    return a + b * cos(2.f * 3.14159 * (c * angle + d));
}

float getMountainMembership(vec3 p) {
    return fbmPerlin(p, 0.5f, 1.f, 24.f, 4, 0.6f, 2.f);
}

float getForestMembership(vec3 p) {
    return fbmPerlin(p, 0.5f, 1.f, 55.f, 3, 0.6f, 3.f);
}

float getGrassMembership(vec3 p) {
    return fbmPerlin(p * 2.5f, 0.5f, 1.f, 23.f, 4, 0.4f, 3.2f);
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

    mountain = getMountainMembership(p);
    grass = getGrassMembership(p);
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
    } else {
        return WATER;
    }

    return WATER;
}

float getBaseTerrainHeight(vec3 p) {
    //return bias(fbmPerlin(p, 0.5f, 0.2f, 11.f, 2, 0.6f, 3.f) / 3.5f, 0.2f);
    return 0.f;
}

float getMountainTerrainHeight(vec3 p) {
    return bias(fbmPerlin(p, 0.5f, 0.2f, 0.f, 5, 0.6f, 3.f) / 1.5f, 0.2f);
}

float getWaterNoise(vec3 p) {
    return fbmPerlin(p, 0.5f, 0.2f, 999.f, 5, 0.6f, 3.f);
}

float getCloudNoise(vec3 p) {
    return fbmPerlin(p, 0.5f, 0.2f, 888.f, 8, 0.8,  1.5f);
}

vec3 deformForGrassNormal(vec3 p) {
    float mod = bias(fbmPerlin(p * 8.f, 0.5f, 0.2f, 69.f, 8, 0.6f, 3.f) / 1.5f, 0.1f);
    return p * (1.f + mod);
}

vec3 deformForForestNormal(vec3 p) {
    float mod = bias(fbmPerlin(p * 10.f, 0.5f, 0.2f, 70.f, 8, 0.6f, 3.f) / 1.5f, 0.5f);
    return p * (1.f + mod);
}

float terrainNoise(vec3 p, int biome) {
    float f = clamp((getGrassMembership(p) - u_GrassCutoff) / (1.f - u_GrassCutoff), 0.f, 1.f);
    return bias(f, 0.2f) * 0.5f;;
}

vec3 deformTerrain(vec3 p, int biome) {
    float mod = terrainNoise(p, biome);
    return p * (1.f + mod);
}

vec3 transformNormalSymmetric(vec3 p, vec3 dp, vec3 normal, int biome) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));

    vec3 dt = deformTerrain(p + u_NormDifferential * tangent, biome);
    vec3 db = deformTerrain(p + u_NormDifferential * bitangent, biome);
    vec3 dt2 = deformTerrain(p - u_NormDifferential * tangent, biome);
    vec3 db2 = deformTerrain(p - u_NormDifferential * bitangent, biome);

    return normalize(cross(db - db2, dt - dt2));
}

vec3 transformNormal(vec3 p, vec3 dp, vec3 normal, int biome) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));

    vec3 dt = deformTerrain(p + u_NormDifferential * tangent, biome);
    vec3 db = deformTerrain(p + u_NormDifferential * bitangent, biome);

    return normalize(cross(dp - db, dp - dt));
}

vec3 transformNormalP(vec3 p, vec3 normal) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));

    vec3 dp = deformForGrassNormal(p);
    vec3 dt = deformForGrassNormal(p + u_NormDifferential * tangent);
    vec3 db = deformForGrassNormal(p + u_NormDifferential * bitangent);

    return (normalize(cross(dp - db, dp - dt)) + normal) / 2.f;
}

vec3 transformNormalF(vec3 p, vec3 normal) {
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));

    vec3 dp = deformForForestNormal(p);
    vec3 dt = deformForForestNormal(p + u_NormDifferential * tangent);
    vec3 db = deformForForestNormal(p + u_NormDifferential * bitangent);

    return normalize(cross(dp - db, dp - dt));
}

vec3 sph2Cart(float r, float theta, float phi) {
    return vec3(
        r * cos(theta) * sin(phi),
        r * sin(theta) * sin(phi),
        r * cos(phi));
}

vec3 transformNormalAdam(vec3 p, vec3 dp, vec3 normal, int biome) {
    float r = length(p);
    float theta = atan(p.y, p.x);
    float phi = atan(length(p.xy), p.z);

    vec3 dx1 = sph2Cart(r, theta + u_NormDifferential, phi);
    vec3 dx2 = sph2Cart(r, theta - u_NormDifferential, phi);
    vec3 dy1 = sph2Cart(r, theta, phi + u_NormDifferential);
    vec3 dy2 = sph2Cart(r, theta, phi - u_NormDifferential);
    //vec3 dz1 = sph2Cart(r + alpha, theta, phi);

    float dx = (terrainNoise(dx1, biome) - terrainNoise(dx2, biome)) / u_NormDifferential;
    float dy = (terrainNoise(dy1, biome) - terrainNoise(dy2, biome)) / u_NormDifferential;
    dx = 1.f / (1.f + exp(-dx));
    dy = 1.f / (1.f + exp(-dy));
    //float dz = terrainNoise(dz1, biome) - terrainNoise(p, biome);
    vec3 local = normalize(vec3(dx, dy, sqrt(1.f - dx*dx - dy*dy)));
    vec3 tangent = normalize(cross(vec3(0.f, 1.f, 0.f), normal));
    vec3 bitangent = normalize(cross(tangent, normal));
    mat3 trans;
    trans[0] = tangent;
    trans[1] = bitangent;
    trans[2] = normal;

    return trans * local;
}

vec3 transformNormalAdamImproved(vec3 p, vec3 dp, vec3 normal, int biome) {
    float r = length(p);
    float theta = atan(p.y, p.x);
    float phi = atan(length(p.xy), p.z);

    vec3 dx1 = sph2Cart(r, theta + u_NormDifferential, phi);
    vec3 dx2 = sph2Cart(r, theta - u_NormDifferential, phi);
    vec3 dy1 = sph2Cart(r, theta, phi + u_NormDifferential);
    vec3 dy2 = sph2Cart(r, theta, phi - u_NormDifferential);
    //vec3 dz1 = sph2Cart(r + alpha, theta, phi);

    vec3 dx = (deformTerrain(dx1, biome) - deformTerrain(dx2, biome));
    vec3 dy = (deformTerrain(dy1, biome) - deformTerrain(dy2, biome));

    return cross(dy, dx);
}