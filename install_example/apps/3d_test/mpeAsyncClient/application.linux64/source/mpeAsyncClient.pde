// AsyncClient for 3d_test

import mpe.client.*;
import mpe.config.*;
import processing.opengl.*;

AsyncClient client;
FileParser sketch_fp, mpe_fp;

String serverIP; // server ip
int asyncPort; // AsyncClient backdoor port on server
int asyncFPS; // AsyncClient framerate (should be same as server fps)
float fov; // field of view (degrees)
float bounds; // size of stampede area on x/z axes

int winWidth = 1000;
int winHeight = 226;

void setup() 
{
    size(winWidth, winHeight, OPENGL);
    frame.setResizable(true);
    background(0);
    stroke(255);

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

    // init 3Dnav
    navSetup(); 
    
    // make a new Client using an ip and listening port of server
    client = new AsyncClient(serverIP, asyncPort);
}

void draw() 
{
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

    // update camera and lookat
    navUpdate();

    // draw world box
    noFill();
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(0, -25, 0);
    box(bounds, 50.0, bounds);
    popMatrix();

    // send data to mpe clients   
    client.broadcast(cam[0] + "," + cam[1] + "," + cam[2] + "," + lookat[0] + "," + lookat[1] + "," + lookat[2]);
    //println(cam[0] + "," + cam[1] + "," + cam[2] + "," + lookat[0] + "," + lookat[1] + "," + lookat[2]); 
}

// load and parse mpe.ini file
void loadMpeFile(String fileString) 
{
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
void loadSketchFile(String fileString) 
{
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
        
        bounds = sketch_fp.getIntValue("bounds");
        if (bounds == -1) {
            bounds = 1000;
        }
    }
    else {   
        asyncPort = 9003;
        asyncFPS = 30;
        fov = 30;
        bounds = 1000;    
    }
}


