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
  moonSpeed: 2,
  continentNumber: 5,
  temparature: 25,
  'Lambert Shader': toggleLambert,
  'Blinn-Phong Shader': toggleCustom,
  currColor: [255, 0, 0, 1],
};

let mainPlanet: Icosphere;
let moonObject: Icosphere;
let moonPos: vec3 = vec3.fromValues(3.0, 0.0, 0.0);
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let time: number = 0;
let currMoonSpeed: number = 2;
let currContinentSize: number = 1;
let currTemp: number = 2; //1: Arctic, 2: Earth, 3: Dessert, 4: Lava
let shader: number = 0;

function loadScene() {
  mainPlanet = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  mainPlanet.create();
  moonObject = new Icosphere(moonPos, 0.25, controls.tesselations);
  moonObject.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function toggleLambert() {
  shader = 0;
}

function toggleCustom() {
  shader = 1;
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
  gui.add(controls, 'moonSpeed', 0, 10).step(1).onChange(function(val){
    currMoonSpeed = val;
  });
  gui.add(controls, 'continentNumber', 1, 10).step(1).onChange(function(val){
    currContinentSize = (val / 5.0);
  });
  gui.add(controls, 'temparature', 0, 100).step(1).onChange(function(val){
    if (val < 10) {
      currTemp = 1;
    } else if (val < 30) {
      currTemp = 2;
    } else if (val < 50) {
      currTemp = 3;
    } else {
      currTemp = 4;
    }
  });
  gui.add(controls, 'Lambert Shader');
  gui.add(controls, 'Blinn-Phong Shader');
  // gui.addColor(controls, "currColor");

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

  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const moon = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ]);

  function rotateY(pos: vec3, a: number) {
    return vec3.fromValues(Math.cos(a) * pos[0] + Math.sin(a) * pos[2], pos[1], -Math.sin(a) * pos[0] + Math.cos(a) * pos[2]);
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
      mainPlanet = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      mainPlanet.create();
    }
    moonPos = rotateY(vec3.fromValues(3, 0, 0), time * (currMoonSpeed / 2.0));

    moonObject = new Icosphere(moonPos, 0.25, prevTesselations);
    moonObject.create();
    // moonObject.center = vec4.fromValues(moonPos[0], moonPos[1], moonPos[2], 1.0);

    let newColor = vec4.fromValues((controls.currColor[0] / 255.0), 
                                    (controls.currColor[1] / 255.0), 
                                    (controls.currColor[2] / 255.0), 1);
    time += 0.01;
    renderer.render(camera, planet, [mainPlanet], newColor, time, currMoonSpeed, currContinentSize, currTemp, shader);
    renderer.render(camera, moon, [moonObject], newColor, time, currMoonSpeed, currContinentSize, currTemp, shader);

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
