import {vec2, vec3, vec4} from 'gl-matrix';
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
  tesselations: 7,
  'Load Scene': loadScene, // A function pointer, essentially
  'Color': [255,245,233],
  'Secondary Color': [247,240,221],
  'Clouds': 0.36,
  'Civilization': 0.6,
  'Landmass': 0.29,

  'Use Numerical Normals' : true
};

let icosphere: Icosphere;
let square: Square;
let farSquare: Square;

let cube: Cube;
let time : number = 0;
let prevTesselations: number = 5;
let mouseX = 0;
let mouseY = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  farSquare = new Square(vec3.fromValues(0, 0, -100000.0));
  farSquare.create();

  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function colArrayToVec4(colArr : number[]) : vec4 {
  return vec4.fromValues(colArr[0] / 255.0, colArr[1] / 255.0, colArr[2] / 255.0, 1);
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
  gui.addColor(controls, 'Color');
  gui.addColor(controls, 'Secondary Color');
  //gui.add(controls, 'Use Numerical Normals', true);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Clouds', 0.0, 1.0);
  gui.add(controls, 'Civilization', 0.0, 1.0);
  gui.add(controls, 'Landmass', 0.0, 1.0);

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
  renderer.setClearColor(234 / 255.0,182 / 255.0, 118.0 / 255.0, 1);
  renderer.setClearColor(17 / 255.0,18 / 255.0, 20 / 255.0, 1);

  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);

  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const fog = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/sdf-fog-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sdf-fog-frag.glsl')),
  ]);
  
  const sky = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/sky-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sky-frag.glsl')),
  ]);

  var date = new Date();
  var initTime = date.getTime();

  // This function will be called every frame
  function tick() {
    var date = new Date();
    var seconds = (date.getTime() - initTime) / 15 ;

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
    console.log("what");

    sky.setCamPos(vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1));
    sky.setTime(seconds);
    sky.setMousePos(vec2.fromValues(mouseX, mouseY));
    sky.setResolution(vec3.fromValues(window.innerWidth, window.innerHeight,1));


    fog.setCamPos(vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1));
    fog.setTime(seconds);
    fog.setMousePos(vec2.fromValues(mouseX, mouseY));
    fog.setClouds(controls["Clouds"] + 2.3);
    fog.setResolution(vec3.fromValues(window.innerWidth, window.innerHeight,1));

    planet.setOceanSize(controls["Landmass"]);
    planet.setCamPos(vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1));
    planet.setGeometryColor(colArrayToVec4(controls["Color"]));
    planet.setSecondaryColor(colArrayToVec4(controls["Secondary Color"]));
    planet.setNumericalNorm(controls["Use Numerical Normals"]);
    planet.setCivilization(controls["Civilization"]);

    //console.log(seconds);
    planet.setTime(seconds);
    planet.setMousePos(vec2.fromValues(mouseX, mouseY));

    // renderer.render(camera, sky, [
    //   farSquare,
    // ]);

    renderer.render(camera, planet, [
      icosphere,
    ]);

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);  

    if(controls["Clouds"] > 0.00001) {
      renderer.render(camera, fog, [
        square,
      ]);
    }

    stats.end();

    ++time;
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

document.addEventListener( 'mousemove', function( event ) {
  mouseX = event.pageX / window.innerWidth;
  mouseY = (window.innerHeight - event.pageY) / window.innerHeight;
});

main();
