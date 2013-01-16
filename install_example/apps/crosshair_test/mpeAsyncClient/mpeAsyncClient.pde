// AsyncClient for crosshair_test

import mpe.client.*;
import mpe.config.*;
import processing.opengl.*;

AsyncClient client;
FileParser sketch_fp, mpe_fp;

String serverIP; // server ip
int asyncPort; // AsyncClient backdoor port on server
int asyncFPS; // AsyncClient framerate (should be same as server fps)
float fov; // field of view (degrees)
float crosshair; // size of cursor crosshair in pixels
float[] mXY = new float[2]; // normalized mouseX and mouseY

int winWidth = 1000;
int winHeight = 226;

void setup() {
    size(winWidth, winHeight, OPENGL);
    frame.setResizable(true);
    background(0);
    noFill();
    stroke(255);
    strokeWeight(3);

    // get path of mpe.ini (only works as application)
    File directory = new File (".");
    String iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/mpe.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }
    // when running as sketch, get path this way
    //iniPath = sketchPath("mpe.ini");
    
    // init with mpe.ini file
    loadMpeFile(iniPath);

    // get path of sketch.ini (only works as application)
    iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/sketch.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }
    // when running as sketch, get path this way
    //iniPath = sketchPath("sketch.ini");
   
    // init with sketch.ini file
    loadSketchFile(iniPath);
    
    frameRate(asyncFPS);
    
    // init perspective (cameraZ and fov setup here same as in MPE)
    float cameraZ = ((height/2.0) / tan(PI * fov/360.0));
    perspective(((fov/180.0) * PI), float(width)/float(height), cameraZ/100.0, cameraZ*10.0); // args 3-4 near/far clip
     
    // make a new Client using an ip and listening port of server
    client = new AsyncClient(serverIP, asyncPort);
}

void draw() {
    // clear the screen     
    background(0);

    // update perspective if window resized (cameraZ and fov setup here same as in MPE)
    if (width != winWidth || height != winHeight) {
        // update winWidth and winHeight to make the perspective stay constant
        // comment them out to skew the viewport to match the aspect ratio of total mpe window size
        //winWidth = width;
        //winHeight = height;
        float cameraZ = ((height/2.0) / tan(PI * fov/360.0));
        perspective(((fov/180.0) * PI), float(winWidth)/float(winHeight), cameraZ/100.0, cameraZ*10.0); // args 3-4 near/far clip      
    }
    
    // get normalized coords of mouse
    mXY[0] = float(mouseX)/width;
    mXY[1] = float(mouseY)/height;
  
    // send data to mpe clients  
    client.broadcast(mXY[0] + "," + mXY[1]);
    //println(mXY[0] + "," + mXY[1]);  
}

// load and parse mpe.ini file
void loadMpeFile(String fileString) {
    mpe_fp = new FileParser(fileString);
       
    if (mpe_fp.fileExists()) {     
        serverIP = mpe_fp.getStringValue("server");
        if (serverIP == null) {
             serverIP = "localhost";
        }
    }
    else {
        serverIP = "localhost";     
    }
}

// load and parse sketch.ini file
void loadSketchFile(String fileString) {
    sketch_fp = new FileParser(fileString);
        
    if (sketch_fp.fileExists()) {    
        asyncPort = sketch_fp.getIntValue("asyncPort");
        if (asyncPort == -1) {
            asyncPort = 9003;
        }
        
        asyncFPS = sketch_fp.getIntValue("asyncFPS");
        if (asyncFPS == -1) {
            asyncFPS = 30;
        }
        
        fov = sketch_fp.getIntValue("fov");
        if (fov == -1) {
            fov = 30;
        }
        
        crosshair = sketch_fp.getIntValue("crosshair");
        if (crosshair == -1) {
            crosshair = 50;
        }
    }
    else { 
        asyncPort = 9003;
        asyncFPS = 30;
        fov = 30;
        crosshair = 50;    
    }
}


