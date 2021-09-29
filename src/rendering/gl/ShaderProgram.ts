import {vec3,vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifTime: WebGLUniformLocation;
  unifNoise_Con: WebGLUniformLocation;
  unifNoise_Ridge: WebGLUniformLocation;
  unifNoise_Mask: WebGLUniformLocation;
  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifoceanDepthMultiplier:WebGLUniformLocation;
  unifoceanFloorDepth:WebGLUniformLocation;
  unifoceanFloorSmoothing:WebGLUniformLocation;
  unifmountainBlend:WebGLUniformLocation;
  unifCameraPos:WebGLUniformLocation;
  unifLightPos:WebGLUniformLocation;
  unifText:WebGLUniformLocation;
  unifTextBool:WebGLUniformLocation;
  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }
    // Vertex
    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");

    // Camera Stuff
    this.unifCameraPos = gl.getUniformLocation(this.prog,"u_CamPos");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifLightPos = gl.getUniformLocation(this.prog,"u_Light_pos");

    // Customized 
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifTime      = gl.getUniformLocation(this.prog, "u_Time");
    this.unifoceanDepthMultiplier      = gl.getUniformLocation(this.prog, "oceanDepthMultiplier");
    this.unifoceanFloorDepth = gl.getUniformLocation(this.prog, "oceanFloorDepth");
    this.unifoceanFloorSmoothing = gl.getUniformLocation(this.prog, "oceanFloorSmoothing");
    this.unifmountainBlend = gl.getUniformLocation(this.prog, "mountainBlend");
    this.unifNoise_Con = gl.getUniformLocation(this.prog, "noise_params_continent");
    this.unifNoise_Ridge = gl.getUniformLocation(this.prog, "noise_params_ridge");
    this.unifNoise_Mask = gl.getUniformLocation(this.prog, "noise_params_mask");
    this.unifText       = gl.getUniformLocation(this.prog, "u_Text");
    this.unifTextBool   =  gl.getUniformLocation(this.prog, "u_TextBool");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }
  setCam(color: vec4) {
    this.use();
    if (this.unifCameraPos !== -1) {
      gl.uniform4fv(this.unifCameraPos, color);
    }
  }
  setLight(color: vec4) {
    this.use();
    if (this.unifLightPos !== -1) {
      gl.uniform4fv(this.unifLightPos, color);
    }
  }
  
  setText(text: WebGLTexture){
    this.use();
    if (this.unifText !== -1) {
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, text);
      gl.uniform1i(this.unifText, 0);
    }
  }
  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  // time
  
  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, time);
    }
  }
  setoceanDepthMultiplier(oceanDepthMultiplier: number) {
    this.use();
    if (this.unifoceanDepthMultiplier !== -1) {
      gl.uniform1f(this.unifoceanDepthMultiplier, oceanDepthMultiplier);
    }
  }

  setoceanFloorDepth(oceanFloorDepth: number) {
    this.use();
    if (this.unifoceanFloorDepth !== -1) {
      gl.uniform1f(this.unifoceanFloorDepth, oceanFloorDepth);
    }
  }
  setoceanFloorSmoothing(oceanFloorSmoothing: number) {
    this.use();
    if (this.unifoceanFloorSmoothing !== -1) {
      gl.uniform1f(this.unifoceanFloorSmoothing,oceanFloorSmoothing);
    }
  }
  setmountainBlend(mountainBlend: number) {
    this.use();
    if (this.unifmountainBlend !== -1) {
      gl.uniform1f(this.unifmountainBlend, mountainBlend);
    }
  }
  setTextBool(n: number) {
    this.use();
    if (this.unifTextBool !== -1) {
      gl.uniform1f(this.unifTextBool, n);
    }
  }
  setNoise_Con(noise_par: Float32Array) {
    this.use();
    if (this.unifNoise_Con !== -1) {
      gl.uniform1fv(this.unifNoise_Con, noise_par);
    }
  }
  setNoise_Ridge(noise_par: Float32Array) {
    this.use();
    if (this.unifNoise_Ridge !== -1) {
      gl.uniform1fv(this.unifNoise_Ridge, noise_par);
    }
  }
  setNoise_Mask(noise_par: Float32Array) {
    this.use();
    if (this.unifNoise_Mask!== -1) {
      gl.uniform1fv(this.unifNoise_Mask, noise_par);
    }
  }


  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
