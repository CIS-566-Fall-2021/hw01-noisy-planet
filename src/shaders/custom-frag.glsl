#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_DesatPercent;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float bias(float b, float t) {
    return (t/((((1.0/b)-2.0)*(1.0-t))+1.0));
}

float gain(float g, float t){
    if (t < 0.5){
        return bias(1.0-g, 2.0*t)/2.0;
    }
    else{
        return 1.0 - bias(1.0-g, 2.0-2.0*t)/2.0;
    }
}

void main()
{   
    vec4 m_color = fs_Col;

    m_color = mix(m_color, u_Color, gain(0.1, u_DesatPercent));
    out_Col = vec4(m_color);
}
