import { vec3, vec4 } from "gl-matrix";
import Drawable from "../rendering/gl/Drawable";
import { gl } from "../globals";

class Cube extends Drawable {
  buffer: ArrayBuffer;
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3, public sideLength: number) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {
    const S = this.sideLength * 0.5;

    this.positions = new Float32Array([
        -1, -1, 1, 1, // front face
        1, -1, 1, 1,
        1, 1, 1, 1,
        -1, 1, 1, 1,
        -1, -1, -1, 1, // back face
        1, -1, -1, 1,
        1, 1, -1, 1,
        -1, 1, -1, 1,
        -1, 1, 1, 1, // top face
        1, 1, 1, 1,
        1, 1, -1, 1,
        -1, 1, -1, 1,
        1, -1, 1, 1, // bottom face
        -1, -1, 1, 1,
        -1, -1, -1, 1,
        1, -1, -1, 1,
        1, -1, 1, 1, // right face
        1, -1, -1, 1,
        1, 1, -1, 1,
        1, 1, 1, 1,
        -1, -1, -1, 1, // left face
        -1, -1, 1, 1,
        -1, 1, 1, 1,
        -1, 1, -1, 1]);

    this.normals = new Float32Array([
        0, 0, 1, 0, // front face
        0, 0, 1, 0,
        0, 0, 1, 0,
        0, 0, 1, 0,
        0, 0, -1, 0, // back face
        0, 0, -1, 0,
        0, 0, -1, 0,
        0, 0, -1, 0,
        0, 1, 0, 0, // top face
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, -1, 0, 0, // bottom face
        0, -1, 0, 0,
        0, -1, 0, 0,
        0, -1, 0, 0,
        1, 0, 0, 0, // right face
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        -1, 0, 0, 0, // left face
        -1, 0, 0, 0,
        -1, 0, 0, 0,
        -1, 0, 0, 0
    ]);

    this.indices = new Uint32Array([
        0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11,
        12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23
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

    // let maxIndexCount = 6;
    // let maxVertexCount = 8;

    // // Create buffers to back geometry data
    // // Index data will ping pong back and forth between buffer0 and buffer1 during creation
    // // All data will be in buffer0 at the end
    // const buffer0 = new ArrayBuffer(
    //   maxIndexCount * 3 * Uint32Array.BYTES_PER_ELEMENT +
    //   maxVertexCount * 4 * Float32Array.BYTES_PER_ELEMENT +
    //   maxVertexCount * 4 * Float32Array.BYTES_PER_ELEMENT
    // );
    // const buffer1 = new ArrayBuffer(
    //   maxIndexCount * 3 * Uint32Array.BYTES_PER_ELEMENT
    // );
    // const buffers = [buffer0, buffer1];
    // let b = 0;

    // const indexByteOffset = 0;
    // const vertexByteOffset = maxIndexCount * 3 * Uint32Array.BYTES_PER_ELEMENT;
    // const normalByteOffset = vertexByteOffset;
    // const positionByteOffset = vertexByteOffset + maxVertexCount * 4 * Float32Array.BYTES_PER_ELEMENT;

    // // Create 3-uint buffer views into the backing buffer to represent triangles
    // // The C++ analogy to this would be something like:
    // // triangles[i] = reinterpret_cast<std::array<unsigned int, 3>*>(&buffer[offset]);
    // let triangles: Array<Uint32Array> = new Array(12);
    // let nextTriangles: Array<Uint32Array> = new Array();
    // for (let i = 0; i < 12; ++i) {
    //   triangles[i] = new Uint32Array(buffers[b], indexByteOffset + i * 3 * Uint32Array.BYTES_PER_ELEMENT, 3);
    // }

    // // Create 3-float buffer views into the backing buffer to represent positions
    // let vertices: Array<Float32Array> = new Array(8);
    // for (let i = 0; i < 8; ++i) {
    //   vertices[i] =new Float32Array(buffer0, vertexByteOffset + i * 4 * Float32Array.BYTES_PER_ELEMENT, 4);
    // }

    // // Initialize normals for a cube
    // vertices[0].set([ -0.5, 0.5, -0.5, 0 ]);
    // vertices[1].set([ 0.5, 0.5, -0.5, 0 ]);
    // vertices[2].set([ 0.5, 0.5, 0.5, 0 ]);
    // vertices[3].set([ -0.5, 0.5, 0.5, 0 ]);
    // vertices[4].set([ -0.5, -0.5, -0.5, 0 ]);
    // vertices[5].set([ 0.5, -0.5, -0.5, 0 ]);
    // vertices[6].set([ 0.5, -0.5, 0.5, 0 ]);
    // vertices[7].set([ -0.5, -0.5, 0.5, 0 ]);

    // // Initialize indices for a cube
    // triangles[0].set([ 0, 1, 2 ]);
    // triangles[1].set([ 0, 2, 3 ]);
    // triangles[2].set([ 4, 5, 6 ]);
    // triangles[3].set([ 4, 6, 7 ]);
    // triangles[4].set([ 1, 2, 6 ]);
    // triangles[5].set([ 1, 5, 6 ]);
    // triangles[6].set([ 0, 4, 7 ]);
    // triangles[7].set([ 0, 3, 7 ]);
    // triangles[8].set([ 0, 1, 5]);
    // triangles[9].set([ 0, 4, 5 ]);
    // triangles[10].set([ 2, 3, 6 ]);
    // triangles[11].set([ 3, 6, 7 ]);

    // if (b === 1) {
    //   // if indices did not end up in buffer0, copy them there now
    //   let temp0 = new Uint32Array(buffer0, 0, 3 * triangles.length);
    //   let temp1 = new Uint32Array(buffer1, 0, 3 * triangles.length);
    //   temp0.set(temp1);
    // }

    // // Populate one position for each normal
    // for (let i = 0; i < vertices.length; ++i) {
    //   let pos = <vec4> new Float32Array(buffer0, positionByteOffset + i * 4 * Float32Array.BYTES_PER_ELEMENT, 4);
    //   vec4.scaleAndAdd(pos, this.center, vertices[i], this.sideLength);
    // }

    // this.buffer = buffer0;
    // this.indices = new Uint32Array(this.buffer, indexByteOffset, triangles.length * 3);
    // this.normals = new Float32Array(this.buffer, normalByteOffset, vertices.length * 4);
    // this.positions = new Float32Array(this.buffer, positionByteOffset, vertices.length * 4);

    // this.generateIdx();
    // this.generatePos();
    // this.generateNor();

    // this.count = this.indices.length;
    // gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    // gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    // gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    // gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    // gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    // gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created cube with ${this.positions.length / 4} vertices`);
  }
}

export default Cube;
