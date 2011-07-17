
varying mediump vec2 v_texCoord;     
uniform mediump float u_offset;

#ifdef VERTEX_SHADER

attribute vec4 a_position;   
attribute vec2 a_texCoord;   

void main() {

    gl_Position = a_position; 
    v_texCoord = a_texCoord;
}

#endif

#ifdef FRAGMENT_SHADER

precision mediump float;                             
uniform sampler2D s_texMono; // 2D texture
uniform sampler2D s_texPal; // 256x1 color palette for texture

#define Mono(m)((m.r+m.g+m.b)/3.)	

void main () {


    vec4 realColor = texture2D(s_texMono, v_texCoord.xy);
    float monoIndex = Mono(realColor);
    float shiftIndex =  u_offset/2. + monoIndex;

    while (shiftIndex>1.) {
        shiftIndex -=1.;
    }
    while (shiftIndex<0.) {
        shiftIndex +=1.;
    }

    gl_FragColor = texture2D(s_texPal,vec2(shiftIndex,0.));
    //gl_FragColor = realColor; // test
}

#endif

