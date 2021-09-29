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
  'Light Position: x': 9.6,
  'Light Position: y': 1.4,
  'Light Position: z': 6.2,
  'City Density': 80.0,
  '% Mountain Glow': 100.0,
  'Show Sun': false
};

let planet: Icosphere;
let moon: Icosphere;

let prevTesselations: number = 5;
let prevLightPos: vec3 = vec3.fromValues(9.6, 1.4, 6.2);
let time = 0;

function loadScene() {
  planet = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  planet.create();
  moon = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  moon.create();
}

function projectToSphere(pos:vec3, center:vec3, radius:number){
  let vector = vec3.fromValues(0, 0, 0);
  let normalized = vec3.fromValues(0, 0, 0);
  let res = vec3.fromValues(0, 0, 0);
  if (vec3.equals(vec3.fromValues(0,0,0), pos)){
    return pos;
  }
  vec3.subtract(vector, pos, center);
  vec3.normalize(normalized, vector);
  vec3.multiply(res, vec3.fromValues(radius, radius, radius), normalized);
  return res;
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
  gui.add(controls, 'Light Position: x', -200, 200).step(0.2);
  gui.add(controls, 'Light Position: y', -200, 200).step(0.2);
  gui.add(controls, 'Light Position: z', -200, 200).step(0.2);
  gui.add(controls, 'City Density', 35, 80).step(1);
  gui.add(controls, '% Mountain Glow', 0, 100).step(1);
  gui.add(controls, 'Show Sun');


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

  const camera = new Camera(vec3.fromValues(0, 0, 3), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(1.0 / 255.0, 11.0/255.0, 28.0/255.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const moonShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);

    // enable transparency
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    renderer.clear();

    // get values from the controls
    let lightPos = vec3.fromValues(controls['Light Position: x'], controls['Light Position: y'], controls['Light Position: z']);
    const showSun = controls['Show Sun'];
    lightPos = showSun ? projectToSphere(lightPos, vec3.fromValues(0,0,0), 1.6) :
                         projectToSphere(lightPos, vec3.fromValues(0,0,0), 3.0);
    const cityDensity = controls['City Density'];
    const mountainGlow = controls['% Mountain Glow'];
    

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      planet = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      planet.create();
      moon = new Icosphere(lightPos, 0.1, prevTesselations - 1);
      moon.create();
    }
    if(lightPos[0] != prevLightPos[0] || lightPos[1] != prevLightPos[1] || 
       lightPos[2] != prevLightPos[2]  && showSun){
        prevLightPos = lightPos;
        moon = new Icosphere(lightPos, 0.1, prevTesselations - 1);
        moon.create();
       }

    renderer.render(camera, lambert, cityDensity, mountainGlow, lightPos, time, [
      planet
    ]);

    if (showSun){
      renderer.render(camera, moonShader, cityDensity, mountainGlow, lightPos, time, [
        moon
      ]);
    }
    
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
    time++;
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
