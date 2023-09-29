import {vec3} from 'gl-matrix';
import {mat4, vec4, vec2} from 'gl-matrix';
import {validateAuthentication, loadSpotifyAPIScript, authenticate} from './spotify-api';
import { embedSpotifyPlaylist } from './spotify-api';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Torus from './geometry/Torus';
import Cylinder from './geometry/Cylinder';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import Cube from './geometry/Cube'
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.

const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
   R: 1.0,
   G: 0.0,
   B: 0.0,
   'hair growth': 4.5,
   'hair length': 1.9,
   'hair twist': 1.0,
   'Reset Everything': resetEverything,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let eye: Icosphere;
let eye2: Icosphere;
let iris: Icosphere;
let iris2: Icosphere;
let mousePosition = vec2.create();
let prevTesselations: number = 5;
let prevHairGrowth: number = 4.5;
let prevHairVolume: number = 1.9;
let prevR: number = 1;
let prevG: number = 0;
let prevB: number = 0;
let time: number = 0;
let hairTwisties: number = 2.5;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(1, 1, 1));
  square.create();
  cube = new Cube(vec3.fromValues(0,0,0))
  cube.create()
  eye = new Icosphere(vec3.fromValues(-0.2,-0.3, 0.65), 1./6.3, controls.tesselations);
  eye.create();
  eye2 = new Icosphere(vec3.fromValues(+0.23,-0.3, 0.65), 1./8.3, controls.tesselations);
  eye2.create();
  iris = new Icosphere(vec3.fromValues(-0.2,-0.3, 0.8), 1./50., controls.tesselations);
  iris.create();
  iris2 = new Icosphere(vec3.fromValues(+0.23,-0.3, 0.76), 1./50., controls.tesselations);
  iris2.create();
}

function resetEverything() {
  controls['hair growth'] = 4.5;
  controls['hair length'] = 1.9;
  controls['hair twist'] = 2.5;
  controls.R = 1.0;
  controls.G = 0.0;
  controls.B = 0.0;
}


function main() {

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'R', 0, 1 ).step(0.1);
  gui.add(controls, 'G', 0, 1).step(0.1);
  gui.add(controls, 'B', 0, 1).step(0.1);
  gui.add(controls, 'hair growth', 0, 10).step(0.1);
  gui.add(controls, 'hair length', 0, 2).step(0.1);
  gui.add(controls, 'hair twist', 0, 10).step(0.1);
  gui.add(controls, 'Reset Everything');

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

  const head = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireboy-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireboy-frag.glsl')),
  ]);

  const eyes = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/eye-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/eye-frag.glsl')),
  ]);

  const irisShaderLeft = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/iris-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/iris-frag.glsl')),
  ]);

  const irisShaderRight = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/iris-Right-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/iris-frag.glsl')),
  ]);
  // This function will be called every frame
  function tick() {
    time += 1;
    camera.update();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    if(controls.R != prevR)
    {
      prevR= controls.R;
    }
    if(controls.G != prevG)
    {
      prevG= controls.G;
    }
    if(controls.B != prevB)
    {
      prevB= controls.B;
    }
    if(controls['hair growth'] != prevHairGrowth) {
      prevHairGrowth = controls['hair growth'];
    }
    if(controls['hair length'] != prevHairVolume) {
      prevHairVolume = controls['hair length'];
    }
    if(controls['hair twist'] != hairTwisties) {
      hairTwisties = controls['hair twist'];
    }

    renderer.render(camera, head, [
      icosphere,
    ], vec4.fromValues(prevR,prevG,prevB,1), time, mousePosition, prevHairGrowth, prevHairVolume, hairTwisties);

    renderer.render(camera, eyes, [
      eye,
      eye2,
    ], vec4.fromValues(prevR,prevG,prevB,1), time, mousePosition, prevHairGrowth, prevHairVolume,  hairTwisties);


    renderer.render(camera, irisShaderLeft, [
      iris,
    ], vec4.fromValues(prevR,prevG,prevB,1), time, mousePosition, prevHairGrowth, prevHairVolume, hairTwisties);

    renderer.render(camera, irisShaderRight, [
      iris2,
    ], vec4.fromValues(prevR,prevG,prevB,1), time, mousePosition, prevHairGrowth, prevHairVolume, hairTwisties);

    console.log(mousePosition);
    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);


  window.addEventListener( 'mousemove', function(e) {
    mousePosition[0] = (e.clientX / window.innerWidth) * 2.0 - 1.0;
    mousePosition[1] = 1.0 - (e.clientY / window.innerHeight) * 2.0;
    eyes.setMouse(mousePosition);
  },false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
