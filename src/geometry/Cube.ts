
// Written by Nathan Devlin, using reference by Adam Mally

import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3) 
  {
    super(); // Call the constructor of the super class. This is required.
    // Set the origin of the cube to center
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() 
  {
      // Positions array
    this.positions = new Float32Array([
      // First Face
      -1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,
      -1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,

      // Second Face
      -1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,
      1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1,
      -1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1,

      // Third Face
      1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,

      // Fourth Face
      -1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      -1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,
      -1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1,
      -1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,

      // Fifth Face
      -1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], -1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,
      -1 + this.center[0], -1 + this.center[1], -1 + this.center[2], 1,

      // Sixth Face
      -1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], 1 + this.center[2], 1,
      1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1,
      -1 + this.center[0], 1 + this.center[1], -1 + this.center[2], 1
    ]);

    // Normals array
    this.normals = new Float32Array([
      // First Face
      0, 0, 1, 0,
      0, 0, 1, 0,
      0, 0, 1, 0,
      0, 0, 1, 0,

      // Second Face
      0, 0, -1, 0,
      0, 0, -1, 0,
      0, 0, -1, 0,
      0, 0, -1, 0,

      // Third Face
      1, 0, 0, 0,
      1, 0, 0, 0,
      1, 0, 0, 0,
      1, 0, 0, 0,

      // Fourth Face
      -1, 0, 0, 0,
      -1, 0, 0, 0,
      -1, 0, 0, 0,
      -1, 0, 0, 0,

      // Fifth Face
      0, -1, 0, 0,
      0, -1, 0, 0,
      0, -1, 0, 0,
      0, -1, 0, 0,

      // Sixth Face
      0, 1, 0, 0,
      0, 1, 0, 0,
      0, 1, 0, 0,
      0, 1, 0, 0
    ]);

    // Indices array
    this.indices = new Uint32Array([
      // First Face
      0, 1, 2, 0, 2, 3, 

      // Second Face
      4, 5, 6, 4, 6, 7,

      // Third Face
      8, 9, 10, 8, 10, 11, 

      // Fourth Face
      12, 13, 14, 12, 14, 15,

      // Fifth Face
      16, 17, 18, 16, 18, 19, 

      // Sixth Face
      20, 21, 22, 20, 22, 23
    ]);


    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created cube`);
  }
};

export default Cube;

