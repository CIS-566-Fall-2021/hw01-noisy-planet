import { vec3, vec4 } from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import { setGL } from './globals';
import ShaderProgram, { Shader } from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 8,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [113, 188, 255, 1],
  speed: 1.0,
  height: 5,
  octaves: 4,
  ambient_light: 2,
  mode: 0,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let time: number = 0;

let prevTesselations: number = 5;

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
  gui.add(controls, 'tesselations', 0, 10).step(1);
  gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'color');
  gui.add(controls, 'speed', 0, 10).step(0.1);
  gui.add(controls, 'height', 1, 15).step(1);
  gui.add(controls, 'octaves', 3, 10).step(1);
  gui.add(controls, 'ambient_light', 1, 5).step(0.1);
  gui.add(controls, 'mode', { lambert: 0, 'blinn-phong': 1, 'ambient-only': 2, 'diffuse-only': 3, pulsing: 4 });

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

  // const renderer = new OpenGLRenderer(canvas);
  // renderer.setClearColor(0.9, 1.0, 1.0, 1);

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.9, 1.0, 1.0, 1);

  gl.enable(gl.DEPTH_TEST);

  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    time++;
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if (controls.tesselations != prevTesselations) {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    renderer.render(
      camera,
      planet,
      [
        icosphere,
        // square,
        // cube,
      ],
      vec4.fromValues(controls.color[0] / 255.0, controls.color[1] / 255.0, controls.color[2] / 255.0, 1),
      time * controls.speed,
      controls.height,
      controls.octaves,
      controls.ambient_light,
      camera.position,
      controls.mode
    );
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener(
    'resize',
    function () {
      renderer.setSize(window.innerWidth, window.innerHeight);
      camera.setAspectRatio(window.innerWidth / window.innerHeight);
      camera.updateProjectionMatrix();
    },
    false
  );

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
