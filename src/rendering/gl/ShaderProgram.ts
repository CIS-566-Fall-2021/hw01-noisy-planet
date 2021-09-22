import { vec4, mat4 } from 'gl-matrix';
import Drawable from './Drawable';
import { gl } from '../../globals';

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
    unifColor: WebGLUniformLocation;
    unifTime: WebGLUniformLocation;
    unifColorDesatPercent: WebGLUniformLocation;
    unifHeightScale: WebGLUniformLocation;
    unifTimeScale: WebGLUniformLocation;
    unifSandHeight: WebGLUniformLocation;
    unifGrassHeight: WebGLUniformLocation;
    unifStoneHeight: WebGLUniformLocation;

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
        this.unifModel = gl.getUniformLocation(this.prog, "u_Model");
        this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
        this.unifViewProj = gl.getUniformLocation(this.prog, "u_ViewProj");
        this.unifColor = gl.getUniformLocation(this.prog, "u_Color");
        this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
        this.unifColorDesatPercent = gl.getUniformLocation(this.prog, "u_DesatPercent");
        this.unifHeightScale = gl.getUniformLocation(this.prog, "u_heightScale");
        this.unifTimeScale = gl.getUniformLocation(this.prog, "u_timeScale");
        this.unifSandHeight = gl.getUniformLocation(this.prog, "u_sandHeight");
        this.unifGrassHeight = gl.getUniformLocation(this.prog, "u_grassHeight");
        this.unifStoneHeight = gl.getUniformLocation(this.prog, "u_stoneHeight");
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
            gl.uniformMatrix4fv(this.unifViewProj, false, vp);
        }
    }

    setGeometryColor(color: vec4) {
        this.use();
        if (this.unifColor !== -1) {
            gl.uniform4fv(this.unifColor, color);
        }
    }

    setTime(time: number) {
        this.use();
        if (this.unifTime !== -1) {
            gl.uniform1f(this.unifTime, time);
        }
    }

    setDesatPercent(desatPercent: number) {
        this.use();
        if (this.unifColorDesatPercent !== -1) {
            gl.uniform1f(this.unifColorDesatPercent, desatPercent);
        }
    }

    setHeightScale(heightScale: number) {
        this.use();
        if (this.unifHeightScale !== -1) {
            gl.uniform1f(this.unifHeightScale, heightScale);
        }
    }

    setTimeScale(timeScale: number) {
        this.use();
        if (this.unifTimeScale !== -1) {
            gl.uniform1f(this.unifTimeScale, timeScale);
        }
    }

    setSandHeight(sandHeight: number) {
        this.use();
        if (this.unifSandHeight !== -1) {
            gl.uniform1f(this.unifSandHeight, sandHeight);
        }
    }

    setGrassHeight(grassHeight: number) {
        this.use();
        if (this.unifGrassHeight !== -1) {
            gl.uniform1f(this.unifGrassHeight, grassHeight);
        }
    }

    setStoneHeight(stoneHeight: number) {
        this.use();
        if (this.unifStoneHeight !== -1) {
            gl.uniform1f(this.unifStoneHeight, stoneHeight);
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
