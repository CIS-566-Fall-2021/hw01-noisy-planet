
// Original code by Adam Mally, additions by Nathan Devlin

import {vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

let activeProgram: WebGLProgram = null;

export class Shader 
{
  shader: WebGLShader;

  constructor(type: number, source: string) 
  {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) 
    {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram 
{
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  
  unifModelInvTr: WebGLUniformLocation;
  
  unifViewProj: WebGLUniformLocation;

  unifOceanColor: WebGLUniformLocation;

  unifLightColor: WebGLUniformLocation;
  
  unifCameraPos: WebGLUniformLocation;

  unifLightPos: WebGLUniformLocation;

  unifBPM: WebGLUniformLocation;

  unifAltitudeMult: WebGLUniformLocation;

  unifTerrainSeed: WebGLUniformLocation;

  unifCurrTick: WebGLUniformLocation;

  unifCurrTime: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) 
  {
    this.prog = gl.createProgram();

    for (let shader of shaders) 
    {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) 
    {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos          = gl.getAttribLocation(this.prog, "vs_Pos");
    
    this.attrNor          = gl.getAttribLocation(this.prog, "vs_Nor");
    
    this.attrCol          = gl.getAttribLocation(this.prog, "vs_Col");
    
    this.unifModel        = gl.getUniformLocation(this.prog, "u_Model");
    
    this.unifModelInvTr   = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    
    this.unifViewProj     = gl.getUniformLocation(this.prog, "u_ViewProj");

    this.unifOceanColor   = gl.getUniformLocation(this.prog, "u_OceanColor");

    this.unifLightColor   = gl.getUniformLocation(this.prog, "u_LightColor");

    this.unifCameraPos    = gl.getUniformLocation(this.prog, "u_CameraPos");

    this.unifLightPos     = gl.getUniformLocation(this.prog, "u_LightPos");

    this.unifBPM          = gl.getUniformLocation(this.prog, "u_bpm");

    this.unifAltitudeMult = gl.getUniformLocation(this.prog, "u_AltitudeMult");

    this.unifTerrainSeed  = gl.getUniformLocation(this.prog, "u_TerrainSeed");
    
    this.unifCurrTick     = gl.getUniformLocation(this.prog, "u_CurrTick");

    this.unifCurrTime     = gl.getUniformLocation(this.prog, "u_Time");
  }

  use() 
  {
    if (activeProgram !== this.prog) 
    {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) 
  {
    this.use();
    if (this.unifModel !== -1) 
    {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) 
    {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) 
  {
    this.use();
    if (this.unifViewProj !== -1) 
    {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) 
  {
    this.use();
    if (this.unifOceanColor !== -1) 
    {
      gl.uniform4fv(this.unifOceanColor, color);
    }
  }

  setLightColor(color: vec4)
  {
    this.use();
    if (this.unifOceanColor !== -1) 
    {
      gl.uniform4fv(this.unifLightColor, color);
    }
  }

  setCameraPos(cameraPos: vec4) 
  {
    this.use();
    if (this.unifCameraPos !== -1) 
    {
      gl.uniform4fv(this.unifCameraPos, cameraPos);
    }
  }

  setLightPos(lightPos: vec4)
   {
    this.use();
    if (this.unifLightPos !== -1)
    {
      gl.uniform4fv(this.unifLightPos, lightPos);
    }
  }

  setBPM(bpm: number)
  {
    this.use();
    if(this.unifBPM !== -1)
    {
      gl.uniform1f(this.unifBPM, bpm);
    }
  }

  setAltitudeMultiplier(altitudeMult: number)
  {
    this.use();
    if(this.unifAltitudeMult !== -1)
    {
      gl.uniform1f(this.unifAltitudeMult, altitudeMult);
    }
  }

  setTerrainSeed(terrainSeed: number)
  {
    this.use();
    if(this.unifTerrainSeed !== -1)
    {
      gl.uniform1f(this.unifTerrainSeed, terrainSeed);
    }
  }

  setCurrTick(currTick: number)
  {
    this.use();
    if(this.unifCurrTick !== -1)
    {
      gl.uniform1f(this.unifCurrTick, currTick);
    }
  }

  setCurrTime(currTime: number)
  {
    this.use();
    if(this.unifCurrTime !== -1)
    {
      gl.uniform1f(this.unifCurrTime, currTime);
    }
  }


  draw(d: Drawable) 
  {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) 
    {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) 
    {
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

