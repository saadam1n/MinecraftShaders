#version 120

void main(){
    discard;
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = vec4(1.0f);
    gl_FragData[1] = vec4(1.0f);
    gl_FragData[2] = vec4(0.0f, 0.0f, 0.0f, 1.0f);
}