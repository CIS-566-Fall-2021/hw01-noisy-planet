precision highp float;

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

void main() {
    vec4 diffuseColor = vec4(0.9f, 0.9f, 0.9f, 1.f);
    vec4 lightSource;
    if (u_UseCameraLight) {
        lightSource = vec4(normalize(u_CameraEye - fs_Pos.xyz), 1.f);
    } else {
        lightSource = fs_LightVec;
    }

    float cloudCutoff = 0.7f;
    vec3 p = fs_Pos.xyz;
    p.y += float(u_Time) / 400.f;
    p.z += float(u_Time) / 400.f;
    float cloud = fbmValueNoise(p,
        144.f,         
        6,
        0.7f,     
        1.9f) * 1.25;
    
    float val;
    if (cloud > cloudCutoff) {
        val = clamp((cloud - cloudCutoff) / (1.f - cloudCutoff), 0.f, 0.97f);
    } else {
        val = 0.f;
    }
    float diffuseTerm = dot(normalize(fs_Nor), normalize(lightSource));

    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
    float ambientTerm = 0.2;
    float lightIntensity = diffuseTerm + ambientTerm; 

    out_Col = vec4(diffuseColor.rgb * lightIntensity, val);
}
