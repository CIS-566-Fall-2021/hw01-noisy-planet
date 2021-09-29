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
  animation_speed: 1,
  global_warming_speed: 1,
  'Load Scene': loadScene, // A function pointer, essentially
};

var palette = {
  color1: [0.0, 0.122 * 255.0, 0.58 * 255.0], // ocean
  color2: [255.0 * 0.761, 255.0 * 0.698, 255.0 * 0.502], // sand
  color3: [.133 * 255.0, .545 * 255.0, .133 * 255.0], // green
  color4: [0.55 * 255.0, 0.55 * 255.0, 0.45 * 255.0], // stone
  color5: [1.0 * 255.0, 0.98 * 255.0, 0.98 * 255.0], // snow
};

let icosphere: Icosphere;
let moon: Icosphere;
let cube: Cube;
let square: Square;
let prevTesselations: number = 6;
let animationSpeed: number = 1.0;
let globalWarmingSpeed: number = 1.0;

let prevColor: vec4 = vec4.fromValues(1.0, 0.0, 0.0, 0.0);
let color_2: vec4 = vec4.fromValues(palette.color2[0] / 255.0, palette.color2[1] / 255.0, palette.color2[2] / 255.0, 1.0);
let color_3: vec4 = vec4.fromValues(palette.color3[0] / 255.0, palette.color3[1] / 255.0, palette.color3[2] / 255.0, 1.0);
let color_4: vec4 = vec4.fromValues(palette.color4[0] / 255.0, palette.color4[1] / 255.0, palette.color4[2] / 255.0, 1.0);
let color_5: vec4 = vec4.fromValues(palette.color5[0] / 255.0, palette.color5[1] / 255.0, palette.color5[2] / 255.0, 1.0);


let prevTime: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  moon = new Icosphere(vec3.fromValues(2.0, 2.0, 0.0), 0.4, controls.tesselations);
  icosphere.create();
  moon.create();
  cube = new Cube(vec3.fromValues(0, 0, 0), 1);
  cube.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
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
  gui.add(controls, 'animation_speed', -5, 5).step(.1);
  gui.add(controls, 'global_warming_speed', .001, 3.0).step(.01);

  gui.addColor(palette, 'color1');
  gui.addColor(palette, 'color2');
  gui.addColor(palette, 'color3');
  gui.addColor(palette, 'color4');
  gui.addColor(palette, 'color5');


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
  renderer.setClearColor(20.0/255.0, 7.0/255.0, 61.0/255.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);

  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const moonRender = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    let currColor : vec4 = vec4.fromValues(palette.color1[0]/255, palette.color1[1]/255, palette.color1[2] / 255.0, 1);
    if(currColor != prevColor)
    {
      prevColor = currColor;
    }

    let currColor2 : vec4 = vec4.fromValues(palette.color2[0]/255, palette.color2[1]/255, palette.color2[2] / 255.0, 1);
    if(currColor2 != color_2)
    {
      color_2 = currColor2;
    }

    let currColor3 : vec4 = vec4.fromValues(palette.color3[0]/255, palette.color3[1]/255, palette.color3[2] / 255.0, 1);
    if(currColor3 != color_3)
    {
      color_3 = currColor3;
    }

    let currColor4 : vec4 = vec4.fromValues(palette.color4[0]/255, palette.color4[1]/255, palette.color4[2] / 255.0, 1);
    if(currColor4 != color_4)
    {
      color_4 = currColor4;
    }

    let currColor5 : vec4 = vec4.fromValues(palette.color5[0]/255, palette.color5[1]/255, palette.color5[2] / 255.0, 1);
    if(currColor5 != color_5)
    {
      color_5 = currColor5;
    }

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    if(controls.animation_speed != animationSpeed) {
      animationSpeed = controls.animation_speed;
    }

    if(controls.global_warming_speed != globalWarmingSpeed) {
      globalWarmingSpeed = controls.global_warming_speed;
    }

    renderer.render(camera, planet, animationSpeed, globalWarmingSpeed, 
      prevColor, color_2, color_3, color_4, color_5, prevTime, [
      icosphere,
      // moon
      //cube
      // square,
    ]);

    renderer.render(camera, moonRender, animationSpeed, globalWarmingSpeed, 
      prevColor, color_2, color_3, color_4, color_5, prevTime, [moon]);

    prevTime++;
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
