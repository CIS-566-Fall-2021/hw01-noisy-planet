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
    tesselations: 6,
    'Load Scene': loadScene, // A function pointer, essentially
    DesaturateColor: [255, 255, 255],
    DesaturatePercent: 0.0,
    LandscapeHeight: 1.5,
    TimeScale: 1.0,
    SandHeight: 0.2,
    GrassHeight: 0.4,
    StoneHeight: 0.75,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 6;

function loadScene() {
    icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
    icosphere.create();
    square = new Square(vec3.fromValues(0, 0, 0));
    square.create();
    cube = new Cube(vec3.fromValues(3, 0, 0));
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
    gui.addColor(controls, 'DesaturateColor').onChange(setAllGeometryColor);
    gui.add(controls, "DesaturatePercent", 0.0, 1.0).step(0.01).onChange(setDesatPercent);
    gui.add(controls, "LandscapeHeight", 0.0, 5.0).step(0.1).onChange(setLandscapeHeight);
    gui.add(controls, "TimeScale", 0.0, 5.0).step(0.1).onChange(setTimeScale);
    gui.add(controls, "SandHeight", 0.1, 0.3).step(0.01).onChange(setSandHeight);
    gui.add(controls, "GrassHeight", 0.3, 0.6).step(0.01).onChange(setGrassHeight);
    gui.add(controls, "StoneHeight", 0.6, 0.9).step(0.01).onChange(setStoneHeight);

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

    const lambert = new ShaderProgram([
        new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
        new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
    ]);
    lambert.setGeometryColor(vec4.fromValues(0, 1, 0, 1));

    const custom = new ShaderProgram([
        new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
        new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
    ]);
    custom.setGeometryColor(vec4.fromValues(1, 1, 1, 1));
    custom.setHeightScale(1.5);
    custom.setTimeScale(1.0);
    custom.setSandHeight(0.2);
    custom.setGrassHeight(0.4);
    custom.setStoneHeight(0.75);

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

        // Render with custom shader
        renderer.render(camera, custom, [
            icosphere,
        ]);

        // Render with Lambert shader
        //renderer.render(camera, lambert, [
        //    icosphere,
        //    square,
        //    cube,
        //]);

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

    // Help function
    function setAllGeometryColor() {
        // lambert.setGeometryColor(vec4.fromValues(controls.DesaturateColor[0] / 255.0, controls.DesaturateColor[1] / 255.0, controls.DesaturateColor[2] / 255.0, 1));
        custom.setGeometryColor(vec4.fromValues(controls.DesaturateColor[0] / 255.0, controls.DesaturateColor[1] / 255.0, controls.DesaturateColor[2] / 255.0, 1));
    }

    function setDesatPercent() {
        custom.setDesatPercent(controls.DesaturatePercent);
    }

    function setLandscapeHeight() {
        custom.setHeightScale(controls.LandscapeHeight);
    }

    function setTimeScale() {
        custom.setTimeScale(controls.TimeScale);
    }

    function setSandHeight() {
        custom.setSandHeight(controls.SandHeight);
    }

    function setGrassHeight() {
        custom.setGrassHeight(controls.GrassHeight);
    }

    function setStoneHeight() {
        custom.setStoneHeight(controls.StoneHeight);
    }
}

main();
