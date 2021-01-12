#version 120

flat varying float fMasks;

void main(){
    /* DRAWBUFFERS:1 */
    gl_FragData[0] = vec4(0.0f, 0.0f, 0.0f, fMasks);
}