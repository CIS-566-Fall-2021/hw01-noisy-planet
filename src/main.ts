import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Cube from './geometry/Cube';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 6,
  'Load Scene': loadScene, // A function pointer, essentially
  Color: [255.0, 255.0, 255.0],
  SnowColor: [255.0, 255.0, 255.0],
  Lambert: true,
  octaves: 5,
  frequency: 2.0,
  bias: 0.6,
  height: 2.0,
  speed: 1.0 
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 6;
let currentTime: number = 0.0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
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
  //gui.addColor(controls, 'Color').onChange(setColor); 
  gui.add(controls, 'Lambert').onChange(setReflectionMode);

  gui.add(controls, 'octaves', 1, 9).step(1).onChange(setOctaves);
  gui.add(controls, 'frequency',1.0,5.0).onChange(setFrequency);
  gui.add(controls, 'bias',0.1,0.9).onChange(setBias);
  gui.add(controls, 'height',1.0,5.0).onChange(setTerrainHeight);
  gui.add(controls, 'speed',0.0,2.0).onChange(setSpeed);

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
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);

  noise.setGeometryColor(vec4.fromValues(1.0, 1.0, 1.0, 1.0));
  noise.setShader(0);
  noise.setOctaves(5);
  noise.setBias(0.6);
  noise.setFrequency(2.0);
  noise.setTerrainHeight(2.0);
  noise.setSpeed(1.0);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    noise.setTime(currentTime);
    currentTime++;

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    renderer.render(camera, noise, [
      icosphere,
      // cube
      // square,
    ]);


    stats.end();

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

  function setColor() {
    noise.setGeometryColor(vec4.fromValues(controls.Color[0] / 255.0, controls.Color[1] / 255.0, controls.Color[2] / 255.0, 1.0));
 }

 function setReflectionMode() {
  if (controls.Lambert) {
    noise.setShader(0);
  }
  else {
    noise.setShader(1);
  }
}

function setOctaves() {
  noise.setOctaves(controls.octaves);
}

function setBias() {
  noise.setBias(controls.bias);
}

function setFrequency() {
  noise.setFrequency(controls.frequency);
}

function setTerrainHeight() {
  noise.setTerrainHeight(controls.height);
}

function setSpeed() {
  noise.setSpeed(controls.speed);
}

}


main();
