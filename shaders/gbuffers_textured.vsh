#version 120

varying vec3 normal;

void main(){
    gl_Position = ftransform();
    normal = gl_Normal;
    gl_TexCoord[0].st = gl_MultiTexCoord0.st;
    gl_TexCoord[1].st = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    gl_FrontColor = gl_Color;
}