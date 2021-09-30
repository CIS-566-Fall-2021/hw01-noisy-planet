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
uniform highp int u_Time; //bug after added
uniform lowp int u_ShadingModel;
uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;

uniform vec3 u_CameraPos;
uniform highp int u_Light;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;  

in float fs_noise;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

//toolbox functions
float bias(float b, float t) {
    return pow(t,log(b)/log(0.5f));
}

float gain(float g, float t) {
    if (t < 0.5f) 
        return bias(1.0-g, 2.0*t) / 2.0;
     else 
        return 1.0 - bias(1.0-g, 2.0-2.0*t) / 2.0;
}

float ease_in_quadratic(float t){
    return t*t;
}

float ease_in_out_quadratic(float t) {
    if (t<0.5)
        return ease_in_quadratic(t*2.0)/2.0;
    else  
        return 1.0 - ease_in_quadratic((1.0-t)*2.0);
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        float time = float(u_Time);

        //ocean - blue
        vec4 oceanCol = mix(diffuseColor, vec4(0.22, 0.3, 0.58,1.0),ease_in_quadratic(fs_noise));
        vec4 terrainCol = vec4(0.35, 0.5, 0.31,1.0);
        vec4 mountainCol = vec4(0.64, 0.56, 0.43,1.0);
        vec4 iceCol = vec4(0.96, 0.99,1.0,1.0);

        float oceanMax = 0.75;
        float terrainMax = 0.9;
        float mountainMax = 1.05;

        if(u_ShadingModel == 5){
          oceanCol = vec4(0.2,0.2,0.2,1.0);
          terrainCol = vec4(0.4,0.4,0.4,1.0);
          mountainCol = vec4(0.6,0.6,0.6,1.0);
          iceCol = vec4(0.8,0.8,0.8,1.0);
          oceanMax = 0.6;
        } else if (u_ShadingModel == 6){
          oceanCol = vec4(0.13,0.13,0.23,1.0);
          terrainCol = vec4(0.02,0.07,0.07,1.0); 
          mountainCol = vec4(0.98,0.9,0.7,1.0)+sin(time*0.02);
          iceCol = vec4(0.05,0.10,0.15,1.0);
          mountainMax = 0.90+0.4*sin(time*0.05);
        }
        
        //terrain - green
        float t1 = smoothstep(oceanMax, terrainMax, fs_noise);
        terrainCol = mix(oceanCol, terrainCol,t1);
        //mountain ranges - yellow
        float t2 = smoothstep(terrainMax, mountainMax, fs_noise);
        mountainCol = mix(terrainCol, mountainCol,t2);
        //ice cap - white
        float t3 = smoothstep(mountainMax, mountainMax+0.1, fs_noise);
        iceCol = mix(mountainCol, iceCol,t3);

        if(fs_noise < oceanMax){
          diffuseColor = oceanCol;
        } else if (fs_noise < terrainMax){
          diffuseColor = terrainCol;
        } else if (fs_noise < mountainMax){
          diffuseColor = mountainCol;
        } else {
          diffuseColor = iceCol;
        }
        vec4 nor = fs_Nor;
        nor.xyz =  normalize(cross(dFdx(fs_Pos.xyz),dFdy(fs_Pos.xyz)));


        vec4 lightDir = fs_LightVec;
        // Calculate the diffuse term for different shading
        float diffuseTerm = dot(normalize(nor), normalize(lightDir));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        float ambientTerm = 0.25*float(u_Light);
        float lightIntensity = (diffuseTerm + ambientTerm) ;
        


        if(u_ShadingModel == 1){
          //blinn-phong
          //average of view vector and light vector
          vec4 fs_CameraPos = vec4(u_CameraPos.xyz,1.0);
          vec4 H = (fs_LightVec + fs_CameraPos) / 2.f;
          H = normalize(H);
          float exp = 80.f;
            // Material base color (before shading)
          diffuseColor += max(pow(dot(normalize(H), normalize(nor)), exp), 0.0);
          out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
          
        } else if (u_ShadingModel == 2){
          // ambient lighting
          out_Col = vec4(diffuseColor.rgb * ambientTerm, diffuseColor.a);
        } else if (u_ShadingModel == 3){
          // diffuse
          
          out_Col = vec4(diffuseColor.rgb * diffuseTerm, diffuseColor.a);
        } else {
          //lambert
          out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        }

       
        
        
}
