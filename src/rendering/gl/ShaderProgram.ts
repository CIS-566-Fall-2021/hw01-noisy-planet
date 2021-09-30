import {vec2, vec3, vec4, mat4} from 'gl-matrix';
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

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifViewProjInv: WebGLUniformLocation;
  unifRes: WebGLUniformLocation;

  unifColor: WebGLUniformLocation;
  unifSecondaryColor: WebGLUniformLocation;

  unifNumericalNorm: WebGLUniformLocation;

  unifTime: WebGLUniformLocation;
  unifMousePos: WebGLUniformLocation;
  unifCamPos: WebGLUniformLocation;
  unifClouds: WebGLUniformLocation;
  unifCity: WebGLUniformLocation;
  unifOcean: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifRes   = gl.getUniformLocation(this.prog, "u_Resolution");
    this.unifViewProjInv   = gl.getUniformLocation(this.prog, "u_ViewProjInv");
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifSecondaryColor      = gl.getUniformLocation(this.prog, "u_SecondaryColor");
    this.unifNumericalNorm      = gl.getUniformLocation(this.prog, "u_NumericalNorm");
    this.unifTime      = gl.getUniformLocation(this.prog, "u_Time");
    this.unifMousePos      = gl.getUniformLocation(this.prog, "u_MousePos");
    this.unifCamPos      = gl.getUniformLocation(this.prog, "u_CameraPos");
    this.unifClouds      = gl.getUniformLocation(this.prog, "u_Clouds");
    this.unifCity      = gl.getUniformLocation(this.prog, "u_CityThreshold");
    this.unifOcean      = gl.getUniformLocation(this.prog, "u_OceanThreshold");

  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
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
      let viewprojinv: mat4 = mat4.create();
      mat4.invert(viewprojinv, vp);

      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
      gl.uniformMatrix4fv(this.unifViewProjInv, false, viewprojinv);
    }
  }

  setInverseViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProjInv, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setSecondaryColor(color: vec4) {
    this.use();
    if (this.unifSecondaryColor !== -1) {
      gl.uniform4fv(this.unifSecondaryColor, color);
    }
  }

  setNumericalNorm(n: boolean) {
    this.use();
    if (this.unifSecondaryColor !== -1) {
      gl.uniform1i(this.unifNumericalNorm, Number(n));
    }
  }



  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, time);
    }
  }

  setMousePos(pos: vec2) {
    this.use();
    if (this.unifMousePos !== -1) {
      gl.uniform2fv(this.unifMousePos, pos);
    }
  }

  setClouds(clouds: number) {
    this.use();
    if (this.unifClouds !== -1) {
      gl.uniform1f(this.unifClouds, clouds);
    }
  }


  setCivilization(civ: number) {
    this.use();
    if (this.unifCity !== -1) {
      gl.uniform1f(this.unifCity, civ);
    }
  }

  setOceanSize(o: number) {
    this.use();
    if (this.unifOcean !== -1) {
      gl.uniform1f(this.unifOcean, o);
    }
  }

  setCamPos(pos: vec4) {
    this.use();
    if (this.unifCamPos !== -1) {
      gl.uniform4fv(this.unifCamPos, pos);
    }
  }

  setResolution(res: vec3) {
    this.use();
    if(this.unifRes !== -1) {
      gl.uniform3fv(this.unifRes, res);
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
