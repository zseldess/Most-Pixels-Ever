import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import mpe.client.*; 
import mpe.config.*; 
import java.io.File; 
import java.awt.Frame; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class mpeAsyncClient extends PApplet {

// AsyncClient for 3d_test






AsyncClient client;
FileParser sketch_fp, mpe_fp;

String serverIP; // server ip
int asyncPort; // AsyncClient backdoor port on server
int asyncFPS; // AsyncClient framerate (should be same as server fps)
float fov; // field of view (degrees)
float bounds; // size of stampede area on x/z axes

int winWidth = 1000;
int winHeight = 226;

public void setup() 
{
    size(winWidth, winHeight, P3D);
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
    float cameraZ = ((height/2.0f) / tan(PI * fov/360.0f));
    perspective(((fov/180.0f) * PI), PApplet.parseFloat(width)/PApplet.parseFloat(height), cameraZ/100.0f, cameraZ*10.0f); // args 3-4 near/far clip

    // init 3Dnav
    navSetup(); 
    
    // make a new Client using an ip and listening port of server
    client = new AsyncClient(serverIP, asyncPort);
}

public void draw() 
{
    // clear the screen     
    background(0);

    // update perspective if window resized (cameraZ and fov setup here same as in MPE)
    if (width != winWidth || height != winHeight) {
        // update winWidth and winHeight to make the perspective stay constant
        // comment them out to skew the viewport to match the aspect ratio of total mpe window size
        //winWidth = width;
        //winHeight = height;
        float cameraZ = ((height/2.0f) / tan(PI * fov/360.0f));
        perspective(((fov/180.0f) * PI), PApplet.parseFloat(winWidth)/PApplet.parseFloat(winHeight), cameraZ/100.0f, cameraZ*10.0f); // args 3-4 near/far clip      
    }

    // update camera and lookat
    navUpdate();

    // draw world box
    noFill();
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(0, -25, 0);
    box(bounds, 50.0f, bounds);
    popMatrix();

    // send data to mpe clients   
    client.broadcast(cam[0] + "," + cam[1] + "," + cam[2] + "," + lookat[0] + "," + lookat[1] + "," + lookat[2]);
    //println(cam[0] + "," + cam[1] + "," + cam[2] + "," + lookat[0] + "," + lookat[1] + "," + lookat[2]); 
}

// load and parse mpe.ini file
public void loadMpeFile(String fileString) 
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
public void loadSketchFile(String fileString) 
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


/*
 3D Navigator (version 1b) - a walking simulator (kind of...)
 -Click and drag the mouse in the Processing window to look around. 
 -Keys w/s/a/d control forward/backward/left/right movement (relative to x/z plane)
 keys r/e control positive/negative movement along y axis (regardless of where you are looking)
 -Press 'SPACEBAR' key to toggle between fast and regular flight speeds
 -Alternatively, if you set the speedKey variable to 1, holding/releasing 'SHIFT' key will
 switch between regular and fast flight speeds. Unfortunately though, the computer won't
 recognize the LEFT 'SHIFT','e', and 'd' keys depressed at the same time. For this movement
 behavior you have to use the RIGHT 'SHIFT' key. 
 -Pressing 's', 'd', and 'e' keys together won't work, as well as 'SHIFT', 's', 'd', 'e'.
 -Combine keys for diagonal movement!
 
 -This version of z_3Dnav1 doesn't use the java.awt.Robot class, and thus 
 does not require a signed certificate when running in a web browser!
 
 Zachary Seldess, 6/23/08 [http://www.zacharyseldess.com]
 */

//---CHANGE THESE VARIABLES TO YOUR LIKING---//
float cam[] = {0.f, 0.f, 0.f}; // set camera coordinates
float lookat[] = {0.f, 0.f, 1.f}; // set lookat coordinates
float lookYangle = PI * 0.5f; // lookat angle constraints (PI == 180 degree rotation, PI*0.5 == 90 degrees)
// NOTE: setting lookYangle to PI or greater won't look good. I recommend not exceeding PI*0.9
float easing = 0.1f; // set smoothing (0.01 == very smooth, 1. == no smoothing)
float dragSpeed = 0.5f; // set rotation speed
int mouseTerritory[] = new int[2]; // the pixel boundaries of the cursor

int speedKey = 0; // 0 sets SPACEBAR as speedKey, 1 sets SHIFT as speedKey
float speedXZ = 0.5f; // adjust speed along x/z plane (when using w/s/a/d keys)
float speedY = 0.1f; // adjust speed along y axis (when using r/e keys)
float fSpeedXZ = 5.0f; // adjust fast speed along x/z plane (when using w/s/a/d keys)
float fSpeedY = 2.5f; // adjust fast speed along y axis (when using r/e keys)
//-------------------------------------------//

float easeX;
float easeY;
float dragX;
float dragY;
float pdragX;
float pdragY;
float deltaX;
float deltaY;
float mX;
float mY;
float currentSpeedXZ = speedXZ;
float currentSpeedY = speedY;
int sizeX;
int sizeY;
int sizeXedge;
int sizeYedge;

boolean forward = false;
boolean backward = false;
boolean left = false;
boolean right = false;
boolean up = false;
boolean down = false;
int dir = 0;


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

//---functions called during setup()---//
public void navSetup() {
    mouseTerritory[0] = width;
    mouseTerritory[1] = height;
    sizeX = width;
    sizeY = height;
    checkScreenSize();
    sizeXedge = sizeX/10;
    sizeYedge = sizeY/10;
    deriveCursor();
    checkRotation();
}
//--------------------------------------//


//---functions called only once during navSetup()---//
public void checkScreenSize() {
    if (sizeX >= mouseTerritory[0]) {
        sizeX = mouseTerritory[0];
    }
    if (sizeY >= mouseTerritory[1]) {
        sizeY = mouseTerritory[1];
    }
}

public void deriveCursor() {
    float x = lookat[0]-cam[0];
    float y = lookat[1]-cam[1];
    float z = lookat[2]-cam[2];  
    float hyp = mag(x, y, z);
    float sine = y/hyp;
    float arcsine = asin(sine);
    float Ymouse = map(arcsine, -lookYangle/2, lookYangle/2, sizeYedge, sizeY-sizeYedge);
    float atangent = atan2(z, x);
    float Xmouse = map(atangent, 0, TWO_PI, sizeXedge, sizeX-sizeXedge);
    if (Xmouse < sizeXedge) {
        Xmouse = (sizeX-sizeXedge) - (sizeXedge-Xmouse);
    }
    if (Xmouse > sizeX-sizeXedge) {
        Xmouse = (Xmouse-(sizeX-sizeXedge)) + sizeXedge;
    }
    if (Ymouse < sizeYedge) {
        Ymouse = PApplet.parseFloat(sizeYedge);
        println("lookat vector exceeds bounds of specified lookYangle: " + lookYangle);
        println("constraining lookat accordingly...");
    }
    if (Ymouse > sizeY-sizeYedge) {
        Ymouse = PApplet.parseFloat(sizeY-sizeYedge);
        println("lookat vector exceeds bounds of specified lookYangle: " + lookYangle);
        println("constraining lookat accordingly...");
    }
    dragX = Xmouse;
    dragY = Ymouse;
    pdragX = Xmouse;
    pdragY = Ymouse;
    easeX = Xmouse;
    easeY = Ymouse;
}
//--------------------------------------//


//--- functions called during draw() ---//
public void keyPressed() {
    if (speedKey == 0) {
        if (key == ' ') {
            if (currentSpeedXZ == speedXZ) currentSpeedXZ = fSpeedXZ;
            else currentSpeedXZ = speedXZ;
            if (currentSpeedY == speedY) currentSpeedY = fSpeedY;
            else currentSpeedY = speedY;
        }
    }
    if (speedKey == 1) {  
        if (key == CODED) {
            if (keyCode == SHIFT) {
                currentSpeedXZ = fSpeedXZ;
                currentSpeedY = fSpeedY;
            }
        }
    }
    if (key == 'w' || key == 'W') forward = true;
    if (key == 's' || key == 'S') backward = true;
    if (key == 'a' || key == 'A') left = true;
    if (key == 'd' || key == 'D') right = true; 
    if (key == 'r' || key == 'R') up = true;
    if (key == 'e' || key == 'E') down = true;
}

public void keyReleased() { 
    if (speedKey == 1) {
        if (key == CODED) {
            if (keyCode == SHIFT) {
                currentSpeedXZ = speedXZ;
                currentSpeedY = speedY;
            }
        }
    }    
    if (key == 'w' || key == 'W') forward = false;
    if (key == 's' || key == 'S') backward = false;
    if (key == 'a' || key == 'A') left = false;
    if (key == 'd' || key == 'D') right = false; 
    if (key == 'r' || key == 'R') up = false;
    if (key == 'e' || key == 'E') down = false;
}

public void navUpdate() {
    mouseTrack(); 
    mouseEase();
    checkDirection();
    switch (dir) {
    case 1:
        translateForward();
        break;
    case 2:
        translateBackward();
        break;
    case 3:
        translateLeft();
        break;
    case 4:
        translateRight();
        break;
    case 5:
        translateForwardLeft();
        break;
    case 6:
        translateForwardRight();
        break;
    case 7:
        translateBackwardLeft();
        break;
    case 8:
        translateBackwardRight();
    } 
    if (up) {
        translateUp();
    } 
    if (down) {
        translateDown();
    }
    checkRotation(); 
    camera(cam[0], cam[1], cam[2], lookat[0], lookat[1], lookat[2], 0, 1, 0);
}

public void mouseTrack() {
    if (mousePressed) {
        deltaX = (mouseX-pmouseX) * dragSpeed;
        deltaY = (mouseY-pmouseY) * dragSpeed; 
        pdragX = dragX;
        dragX += deltaX;
        dragY += deltaY;

        if (deltaX < 0) {
            if (dragX < sizeXedge) {
                dragX = sizeX-sizeXedge;
            }
        }
        if (deltaX > 0) {
            if (dragX > sizeX-sizeXedge) {
            }
        }

        if (dragY < sizeYedge) {
            dragY = sizeYedge;
        }
        if (dragY > sizeY-sizeYedge) {
            dragY = sizeY-sizeYedge;
        }
    }
}

public void mouseEase() {  
    if (dragX < sizeXedge*2 && pdragX > sizeX-(sizeXedge*2)) {
        easeX = easeX - (sizeX-(sizeXedge*2));
    }
    if (dragX > sizeX-(sizeXedge*2) && pdragX < sizeXedge*2) {
        easeX = easeX + (sizeX-(sizeXedge*2));
    }
    float dx = dragX - easeX;  
    if (abs(dx) > 1) {
        easeX += dx * easing;
    }
    float dy = dragY - easeY;  
    if (abs(dy) > 1) {
        easeY += dy * easing;
    }
}

public void checkDirection() {
    if (forward && left) dir = 5;
    else if (forward && right) dir = 6;
    else if (backward && left) dir = 7;
    else if (backward && right) dir = 8;
    else if (forward) dir = 1;
    else if (backward) dir = 2;
    else if (left) dir = 3;
    else if (right) dir = 4;
    else dir = 0;
}

public void checkRotation() {
    mX = ((easeX-sizeXedge)/PApplet.parseFloat(sizeX-(sizeXedge*2)))*TWO_PI; // scale mouseX movement between 0 and 2*PI
    mY = ((easeY-sizeYedge)/PApplet.parseFloat(sizeY-(sizeYedge*2)))*lookYangle - lookYangle/2;
    lookat[0] = cam[0] + cos(mX)*cos(mY);
    lookat[1] = cam[1] + sin(mY);
    lookat[2] = cam[2] + sin(mX)*cos(mY);
}

public void translateForward() {
    cam[0] = cam[0] + (cos(mX) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX) * currentSpeedXZ);
}

public void translateBackward() {
    cam[0] = cam[0] + (cos(mX-PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-PI) * currentSpeedXZ);
}

public void translateLeft() {
    cam[0] = cam[0] + (cos(mX-HALF_PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-HALF_PI) * currentSpeedXZ);
}

public void translateRight() {
    cam[0] = cam[0] + (cos(mX+HALF_PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+HALF_PI) * currentSpeedXZ);
}

public void translateForwardLeft() {
    cam[0] = cam[0] + (cos(mX-(PI*0.25f)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-(PI*0.25f)) * currentSpeedXZ);
}

public void translateForwardRight() {
    cam[0] = cam[0] + (cos(mX+(PI*0.25f)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+(PI*0.25f)) * currentSpeedXZ);
}

public void translateBackwardLeft() {
    cam[0] = cam[0] + (cos(mX-(PI*0.75f)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-(PI*0.75f)) * currentSpeedXZ);
}

public void translateBackwardRight() {
    cam[0] = cam[0] + (cos(mX+(PI*0.75f)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+(PI*0.75f)) * currentSpeedXZ);
}

public void translateUp() {
    cam[1] -= currentSpeedY;
}

public void translateDown() {
    cam[1] += currentSpeedY;
}
//--------------------------------------//

    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "mpeAsyncClient" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
