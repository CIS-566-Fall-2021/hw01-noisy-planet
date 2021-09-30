import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  Color: [255, 0, 0],
  Planet: 1,
  MultiplyNoiseInput: 1,
  AnimationSpeed: 0,
  RotateLightX: 0,
  RotateLightY: 0,
  RotateLightZ: 0,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let time: number = 0;
let prevShader: number = 1;
let currShader: ShaderProgram;
let prevNoiseInput: number = 0.1;
let prevAnimationSpeed: number = 0;
let prevRotationX: number = 0;
let prevRotationY: number = 0;
let prevRotationZ: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
  controls.MultiplyNoiseInput = 1;
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
  //gui.addColor(controls, 'Color').onChange(updateColor);
  gui.add(controls, 'Planet', 1, 4).step(1);
  gui.add(controls, 'MultiplyNoiseInput', 0.1, 5).step(0.1);
  gui.add(controls, 'AnimationSpeed', 0, 10).step(0.1);
  gui.add(controls, 'RotateLightX', 0, 360).step(1);
  gui.add(controls, 'RotateLightY', 0, 360).step(1);
  gui.add(controls, 'RotateLightZ', 0, 360).step(1);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
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
  renderer.setClearColor(20 / 255, 19 / 255, 36 / 255, 1);
    gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/earth-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/earth-frag.glsl')),
  ]);

  const lambertDeform = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/starburst-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/starburst-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/biome3-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/biome3-frag.glsl')),
  ]);

  const noiseDeform = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/biome4-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/biome4-frag.glsl')),
  ]);

  currShader = lambert;

  function updateColor() {
    let col = vec4.fromValues(controls.Color[0] / 255,
                              controls.Color[1] / 255,
                              controls.Color[2] / 255, 1);
    renderer.render(camera, lambert, [cube], col, time);
  }


  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
      square = new Square(vec3.fromValues(0, 0, 0));
      square.create();
      cube = new Cube(vec3.fromValues(0, 0, 0));
      cube.create();
    }

    if (controls.Planet != prevShader) {
      prevShader = controls.Planet;
      if (controls.Planet == 1) {
        currShader = lambert;
      } else if (controls.Planet == 2) {
        currShader = lambertDeform;
      } else if (controls.Planet == 3) {
        currShader = noise;
      } else if (controls.Planet == 4) {
        currShader = noiseDeform;
      }
      currShader.setNoiseInput(1);
      currShader.setAnimationSpeed(controls.AnimationSpeed);
    }

    if(controls.MultiplyNoiseInput != prevNoiseInput)
    {
      prevNoiseInput = controls.MultiplyNoiseInput;
      currShader.setNoiseInput(controls.MultiplyNoiseInput);
    }

    if(controls.AnimationSpeed != prevAnimationSpeed)
    {
      prevAnimationSpeed = controls.AnimationSpeed;
      currShader.setAnimationSpeed(controls.AnimationSpeed);
    }

    if(controls.RotateLightX != prevRotationX)
    {
      prevRotationX = controls.RotateLightX;
      currShader.setRotationAngleX(controls.RotateLightX);
    }

    if(controls.RotateLightY != prevRotationY)
    {
      prevRotationY = controls.RotateLightY;
      currShader.setRotationAngleY(controls.RotateLightY);
    }

    if(controls.RotateLightZ != prevRotationZ)
    {
      prevRotationZ = controls.RotateLightZ;
      currShader.setRotationAngleZ(controls.RotateLightZ);
    }

    currShader.setCamera(vec4.fromValues(camera.getEye()[0], camera.getEye()[1], camera.getEye()[2], 1.0));

    let col = vec4.fromValues(controls.Color[0] / 255,
                              controls.Color[1] / 255,
                              controls.Color[2] / 255, 1);
    renderer.render(camera, currShader, [
      icosphere,
      //square,
      //cube
    ], col, time);
      stats.end();
      time++;

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
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
