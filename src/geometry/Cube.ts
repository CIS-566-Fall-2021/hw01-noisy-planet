import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
    buffer: ArrayBuffer;
    indices: Uint32Array;
    positions: Float32Array;
    normals: Float32Array;
    center: vec4;

    constructor(center: vec3) {
        super(); // Call the constructor of the super class. This is required.
        this.center = vec4.fromValues(center[0], center[1], center[2], 1);
    }

    create() {

        this.indices = new Uint32Array([
            2, 5, 11,
            2, 8, 11,
            0, 6, 18,
            0, 12, 18,
            1, 13, 16,
            1, 4, 16,
            3, 15, 21,
            3, 9, 21,
            7, 19, 22,
            7, 10, 22,
            14, 17, 23,
            14, 20, 23]);
        this.normals = new Float32Array([
            -1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            -1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, 1, 0,
            1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, 1, 0,
            -1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, -1, 0,
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, -1, 0,
            -1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, -1, 0,
            1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, -1, 0]);
        this.positions = new Float32Array([
            -1, 1, 1, 1,
            -1, 1, 1, 1,
            -1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            -1, -1, 1, 1,
            -1, -1, 1, 1,
            -1, -1, 1, 1,
            1, -1, 1, 1,
            1, -1, 1, 1,
            1, -1, 1, 1,
            -1, 1, -1, 1,
            -1, 1, -1, 1,
            -1, 1, -1, 1,
            1, 1, -1, 1,
            1, 1, -1, 1,
            1, 1, -1, 1,
            -1, -1, -1, 1,
            -1, -1, -1, 1,
            -1, -1, -1, 1,
            1, -1, -1, 1,
            1, -1, -1, 1,
            1, -1, -1, 1]);

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