import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, color: Array<number>, time: number, dry: number, hot: number, octaves: number, drawables: Array<Drawable>) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let colorVec = vec4.fromValues(color[0] / 255, color[1] / 255, color[2] / 255, 1);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(colorVec);
    prog.setTime(time);
    prog.setDry(dry * 2.0 / 100 - 1);
    prog.setHot(hot * 2.0 / 100 - 1);
    prog.setOctavity(octaves * 1.0);
    prog.setCamera(camera.direction);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
