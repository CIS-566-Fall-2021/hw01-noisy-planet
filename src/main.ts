import {vec3,vec4} from 'gl-matrix';
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
  color:[122,0,255],
  'Set Text': Settexture,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let time : number = 0;
let prevTesselations: number = 5;
let set_text: number = -1;
function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  if(set_text==1){
    icosphere.loadTexture('https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/ab371d58-f694-4953-a2e5-c79acedd9f56/dcuxgeq-1005a082-f321-4d7c-80d7-5cb2e4ffda89.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcL2FiMzcxZDU4LWY2OTQtNDk1My1hMmU1LWM3OWFjZWRkOWY1NlwvZGN1eGdlcS0xMDA1YTA4Mi1mMzIxLTRkN2MtODBkNy01Y2IyZTRmZmRhODkucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.wAvefXk3lTLluz8RfuvjXvRWBMik2psG6kWva8Fbe2I');
  }
  }
function Settexture(){
  set_text = -set_text;
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
  gui.add(controls, 'tesselations', 0, 9).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Set Text');
  

  // set up GUI 
  var c = gui.addFolder('Terrain general setting');
  const continent_obj = {
    oceanDepthMultiplier:10.0,
    oceanFloorDepth:1.0,
    oceanFloorSmoothing:0.5,
    mountainBlend:0.2
  };
  c.add(continent_obj,'oceanDepthMultiplier',0,100);
  c.add(continent_obj,'oceanFloorDepth',0,10);
  c.add(continent_obj,'oceanFloorSmoothing',0,10);
  c.add(continent_obj,'mountainBlend',0,10);
  c.open();

  var d = gui.addFolder('Light Position');
  const lightpos_obj = {
    x:5,
    y:5,
    z:3,
  };
  d.add(lightpos_obj,'x',-10,10);
  d.add(lightpos_obj,'y',-10,10);
  d.add(lightpos_obj,'z',-10,10);
  var f = gui.addFolder('Noise Control - Continent');
  const noise_con_obj = {
    octaves: 5,
    persistance: 0.5,
    lacunarity: 0.5,
    scale: 0.8,
    multiplier: 4.0,
    vertical_shift: 0.1,
    amplitude: 2.0
  };
  f.add(noise_con_obj, 'octaves', 1, 9).step(1);
  f.add(noise_con_obj, 'persistance',0.00,100.0);
  f.add(noise_con_obj, 'lacunarity',0.00,100.0);
  f.add(noise_con_obj, 'scale',0.00,100.00);
  f.add(noise_con_obj, 'multiplier',0.00,100.0);
  f.add(noise_con_obj, 'vertical_shift',0.00,100.0);
  f.add(noise_con_obj, 'amplitude',0.00,100.0);

  var f_2 = gui.addFolder('Noise Control - Ridge');
  const noise_rid_obj = {
    octaves: 5,
    persistance: 0.5,
    lacunarity: 0.5,
    scale: 1.5,
    multiplier: 11.0,
    power:3.0,
    gain:0.8,
    vertical_shift: 0.0,
    amplitude: 2.0
  };
  f_2.add(noise_rid_obj, 'octaves', 1, 9).step(1);
  f_2.add(noise_rid_obj, 'persistance',0.00,100.0);
  f_2.add(noise_rid_obj, 'lacunarity',0.00,100.0);
  f_2.add(noise_rid_obj, 'scale',0.00,100.0);
  f_2.add(noise_rid_obj, 'multiplier',0.00,100.0);
  f_2.add(noise_rid_obj, 'vertical_shift',0.00,100.0);
  f_2.add(noise_rid_obj, 'power',0.00,100.0);
  f_2.add(noise_rid_obj, 'gain',0.00,100.0);
  f_2.add(noise_rid_obj, 'amplitude',0.00,100.0);

  var f_3 = gui.addFolder('Noise Control - Mountain Mask');
  const noise_mask_obj = {
    octaves: 5,
    persistance: 0.5,
    lacunarity: 0.5,
    scale: 0.8,
    multiplier: 0.2,
    vertical_shift: 0.1,
    amplitude: 2.0
  };
  f_3.add(noise_mask_obj, 'octaves', 1, 9).step(1);
  f_3.add(noise_mask_obj, 'persistance',0.0,1.0);
  f_3.add(noise_mask_obj, 'lacunarity',0.1,0.9);
  f_3.add(noise_mask_obj, 'scale',0.01,1.0);
  f_3.add(noise_mask_obj, 'multiplier',0.01,10.0);
  f_3.add(noise_mask_obj, 'vertical_shift',0.01,10.0);
  f_3.add(noise_mask_obj, 'amplitude',0.01,10.0);



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
    }

    // setup time
    lambert.setTime(time++);

    // setup shader controllable stuff
    lambert.setGeometryColor(vec4.fromValues(controls.color[0]/255.0, 
      controls.color[1]/255.0,controls.color[2]/255.0, 1));
    let noise_parameter_continent_array: Float32Array = new Float32Array([noise_con_obj.octaves,
      noise_con_obj.persistance,noise_con_obj.lacunarity,
      noise_con_obj.scale,noise_con_obj.multiplier,
      noise_con_obj.vertical_shift,noise_con_obj.amplitude]);
    let noise_parameter_ridge_array: Float32Array = new Float32Array([noise_rid_obj.octaves,
      noise_rid_obj.persistance,noise_rid_obj.lacunarity,noise_rid_obj.scale,
      noise_rid_obj.multiplier,noise_rid_obj.power,noise_rid_obj.gain,
      noise_rid_obj.vertical_shift,noise_rid_obj.amplitude]);
    let noise_parameter_mask_array: Float32Array = new Float32Array([noise_mask_obj.octaves,
      noise_mask_obj.persistance,noise_mask_obj.lacunarity,noise_mask_obj.scale,
      noise_mask_obj.multiplier,noise_mask_obj.vertical_shift,noise_mask_obj.amplitude]);
         
    lambert.setNoise_Con(noise_parameter_continent_array);
    lambert.setNoise_Ridge(noise_parameter_ridge_array);
    lambert.setNoise_Mask(noise_parameter_mask_array);
    lambert.setoceanDepthMultiplier(continent_obj.oceanDepthMultiplier);
    lambert.setoceanFloorDepth(continent_obj.oceanFloorDepth);
    lambert.setoceanFloorSmoothing(continent_obj.oceanFloorSmoothing);
    lambert.setmountainBlend(continent_obj.mountainBlend);
    
    lambert.setTextBool(set_text);
    lambert.setCam(vec4.fromValues(camera.position[0],camera.position[1],camera.position[2],1.0));
    lambert.setLight(vec4.fromValues(lightpos_obj.x,lightpos_obj.y,lightpos_obj.z,1.0));
    renderer.render(camera, lambert, [
      icosphere
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
}

main();
