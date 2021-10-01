uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec3 u_CameraEye;
uniform bool u_UseCameraLight;
uniform bool u_ColorTerrain;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 colorWheelTransition(float angle) {
    // base is grass
    vec3 a = vec3(0.190, 0.590, 0.190);
    vec3 b = vec3(0.500, -0.002, 0.500);
    vec3 c = vec3(0.590, 0.690, 0.590);
    vec3 d = vec3(0.410, 1.098, 0.410);
    return (a + b * cos(2.f * 3.14159 * (c * angle + d))) * 0.65f;
}

vec3 colorWheelTransition2(float angle) {
    // base is grass
    vec3 a = vec3(0.070, 0.468, 0.070);
    vec3 b = vec3(0.500, -0.112, 0.500);
    vec3 c = vec3(0.188, -0.252, 0.188);
    vec3 d = vec3(0.938, 1.658, 0.938);
    return (a + b * cos(2.f * 3.14159 * (c * angle + d))) * 0.75f;
}

vec3 colorWheelEarth(float angle) {
    // base is grass
    vec3 a = vec3(0.500, 0.660, 0.298);
    vec3 b = vec3(0.328, -0.222, 0.548);
    vec3 c = vec3(0.528, -0.362, 0.468);
    vec3 d = vec3(0.438, -0.052, 0.498);
    return (a + b * cos(2.f * 3.14159 * (c * angle + d))) * 0.75f;
}

vec4 getBiomeColor(vec3 p, vec3 normal, float mountain, float forest, float grass, int biome) {
    if (biome == WATER) {
        vec3 wp = 0.1f * vec3(0.f, 0.f, float(u_Time) / 50.f) + p;
        float water = getWaterNoise((vec3(mountain, forest, grass) + wp) * 2.f);
        return vec4(colorWheelWater(water + 4.f * gain(dot(fs_Nor.xyz, normalize(u_CameraEye)), 0.2)), 1.f);
    } else if (biome == FOREST) {
        float perls = randomNoise3(p);
        return vec4(colorWheelForest(bias(perls, 0.25f)) * 0.62f, 1.f);
    } else {
        if (biome == MOUNTAIN) {
            vec3 originalNormal = normalize(p);
            vec3 perp = normalize(cross(originalNormal, vec3(0.f,1.f,0.f)));
            float v1 = clamp(dot(originalNormal, normal), 0.f, 1.f);
            float v2 = clamp(dot(normal, perp), 0.f, 1.f);
            vec2 v = 1.f - vec2(v1, v2);
            return vec4(colorWheelTransition(bias(dot(v,v), 0.8f)), 1.f);
        }

        float grass2 = getGrassMembership(p * 16.f);
        return vec4(colorWheelEarth(bias(grass2, bias(grass, 0.2f))), 1.f);
    }
}

void main() {
    vec3 p = fs_Pos.xyz;
    vec4 diffuseColor = vec4(0.5, 0.5, 0.5, 1.f);
    vec4 lightSource;
    if (u_UseCameraLight) {
        lightSource = vec4(normalize(u_CameraEye - fs_Pos.xyz), 1.f);
    } else {
        lightSource = fs_LightVec;
    }

    vec4 normal = fs_Nor;
    float mountain = 0.f, forest = 0.f, grass = 0.f;
    int biome = getBiome(p, mountain, forest, grass);

    vec3 p2 = deformTerrain(p, biome);
    if (biome == FOREST) {
        normal = (vec4(transformNormal(fs_Pos.xyz, p2, normal.xyz, biome), 1.f) + normal) / 2.f;
    } else if (u_SymmetricNorm) {
        normal = vec4(transformNormalSymmetric(fs_Pos.xyz, p2, normal.xyz, biome), 1.f);
    } else {
        normal = vec4(transformNormal(fs_Pos.xyz, p2, normal.xyz, biome), 1.f);
    }

    if (u_ColorTerrain) {
        diffuseColor = getBiomeColor(p, normal.xyz, mountain, forest, grass, biome);
    }

    //diffuseColor = vec4(colorWheel1(perlin(p, 0.125, 1.f, 1.f)), 1.f);

    float diffuseTerm = dot(normalize(normal), normalize(lightSource));
    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
    float ambientTerm = 0.2;
    float lightIntensity = diffuseTerm + ambientTerm; 
    float bf_highlight = max(pow(dot(normalize(normal), normalize(lightSource)), 12.f), 0.f);
    out_Col = vec4(diffuseColor.rgb * (lightIntensity + bf_highlight), diffuseColor.a);
}
