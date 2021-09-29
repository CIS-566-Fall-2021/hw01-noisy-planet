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

  render(camera: Camera, prog: ShaderProgram, animation_speed: number, global_warming_speed: number,
      color: vec4, color2: vec4, color3: vec4, color4: vec4, color5: vec4, 
      time:number, drawables: Array<Drawable>) {

    let model = mat4.create();
    let viewProj = mat4.create();

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setCameraEye([camera.getEye()[0], camera.getEye()[1], camera.getEye()[2], 1.0]);
    prog.setGeometryColor(color);
    prog.setColor2(color2);
    prog.setColor3(color3);
    prog.setColor4(color4);
    prog.setColor5(color5);
    prog.setTime(time);
    prog.setAnimationSpeed(animation_speed);
    prog.setGlobalWarmingSpeed(global_warming_speed);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
