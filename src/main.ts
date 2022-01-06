import { vec3, vec4, mat4 } from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import { gl, setGL } from './globals';
import ShaderProgram, { Shader } from './rendering/gl/ShaderProgram';
export interface IIndexable {
  [key: string]: any;
}
// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls : IIndexable = {
  tesselations: 6,
  'Load Scene': loadScene, // A function pointer, essentially
  u_UseCameraLight: true,
  u_Seed: 0,
  u_GrassCutoff: 0.5,
  u_MountainCutoff: 0.59,
  u_ForestCutoff: 0.3,
  u_MountainSpacing: 0.005,
  u_DeformTerrain: true,
  u_ColorTerrain: true,
  u_AnalyticNorm: true,
  u_NormDifferential: 0.001,
  u_MountainGrassCutoff: 0.01
};

let icosphere: Icosphere;
let icosphere2: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere2 = new Icosphere(vec3.fromValues(0, 0, 0), 1.2, 2);
  icosphere.create();
  icosphere2.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();

  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
  gl.blendEquation(gl.FUNC_ADD);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');

  for (let v in controls) {
    if (v.startsWith("u_")) {
      gui.add(controls, v);
    }
  }

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement>document.getElementById('canvas');
  const gl = <WebGL2RenderingContext>canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  let uniformVars = [];
  for (let key in controls) {
    if (key.startsWith("u_")) {
      uniformVars.push(key);
    }
  }

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/shared-procedural.glsl') + '\n' + require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/shared-procedural.glsl') + '\n' + require('./shaders/lambert-frag.glsl')),
  ], uniformVars);

  const cloud = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/shared-procedural.glsl') + '\n' + require('./shaders/cloud-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/shared-procedural.glsl') + '\n' + require('./shaders/cloud-frag.glsl'))
  ], uniformVars);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if (controls.tesselations != prevTesselations) {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    for (let key in controls) {
      if (key.startsWith("u_")) {
        lambert.setCustomUniform(key, controls[key]);
        cloud.setCustomUniform(key, controls[key]);
      }
    }

    lambert.tickTime();
    lambert.setCameraEye(camera.controls.eye);
    lambert.setModelMatrix(mat4.translate(mat4.create(), mat4.create(), vec3.fromValues(4, 0, 0)));
    renderer.render(camera, lambert, [
      icosphere
    ]);

    cloud.tickTime();
    cloud.setCameraEye(camera.controls.eye);
    cloud.setModelMatrix(mat4.translate(mat4.create(), mat4.create(), vec3.fromValues(4, 0, 0)));
    renderer.render(camera, cloud, [
      icosphere2
    ]);

    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function () {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
