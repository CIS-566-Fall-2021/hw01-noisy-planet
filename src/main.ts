import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Cube from './geometry/Cube';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'terrain frequency': 0.5,
  'earth to alien': 0.0,
  'forest density': 0.2,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [255, 0, 255]
};

let icosphere: Icosphere;
let cube: Cube;
let square: Square;

let prevTesselations: number = 5;
let cubeColor: vec4 = vec4.fromValues(1, 0, 1, 1);

// Procedural Controls
let terrainFreq: number = 0.5;
let earthToAlien: number = 0.0;
let forestScale: number = 0.2;

let time: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
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

  gui.addColor(controls, 'color').onChange( function() { cubeColor = vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, 1) } );;
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'terrain frequency', 0.3, 2.0).step(0.05).onChange(function() { terrainFreq = controls['terrain frequency'] });
  gui.add(controls, 'earth to alien', 0.0, 1.0).step(0.05).onChange(function() { earthToAlien = controls['earth to alien'] });
  gui.add(controls, 'forest density', 0.0, 1.0).step(0.05).onChange(function() { forestScale = controls['forest density'] });
  gui.add(controls, 'Load Scene');

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
  
  // Create starry outerspace clear color
  let darkBlue = vec4.fromValues(0.0 / 11.0, 0.0 / 255.0, .0 / 255.0, 1);
  renderer.setClearColor(darkBlue);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const planet_shader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  // const custom_shader = new ShaderProgram([
  //   new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
  //   new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  // ]);

  // This function will be called every frame
  function tick() {

    planet_shader.setTime(time);
    planet_shader.setTerrainFreq(terrainFreq);
    planet_shader.setEarthToAlien(earthToAlien);
    planet_shader.setForestScale(forestScale);
    planet_shader.setCamera([camera.getEye()[0], camera.getEye()[1], camera.getEye()[2], 1.0]);

    time++;

    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    renderer.render(camera, planet_shader, [
      icosphere,
    ], cubeColor);
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
}

main();
