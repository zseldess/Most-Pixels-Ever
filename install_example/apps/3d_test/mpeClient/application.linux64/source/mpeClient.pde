// Render client for 3d_test

import mpe.client.*;
import mpe.config.*;
import javax.vecmath.Point3d;
import java.io.File;
import java.awt.Frame;

// variables defined in sketch.ini file
float fov; // field of view (degrees)
float bounds; // size of stampede area on x/z axes

float[] cam = {0., 0., 0.};
float[] lookat = {0., 0., 1.};

// a client object
TCPClient client;
// stays false until all clients have connected
boolean start = false;

// object to parse sketch.ini
FileParser sketch_fp;

static public void main(String args[]) 
{
    Frame frame = new Frame("testing");
    frame.setUndecorated(true);
    PApplet applet = new mpeClient();
    frame.add(applet);
    applet.init();
    
    // get path of mpe.ini (only works as application)
    File directory = new File (".");
    String iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/mpe.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }

    // parse mpe.ini, get localScreenSize, fov fields
    int[] winXY = {200, 200};
    FileParser fp = new FileParser(iniPath);
    if (fp.fileExists()) {  
        winXY = fp.getIntValues("localScreenSize");
        if (winXY[0] == -1 || winXY[1] == -1) {
            winXY[0] = 200;
            winXY[1] = 200;
        }
    }

    // set frame size from localScreenSize array
    frame.setBounds(0, 0, winXY[0], winXY[1]); 
    frame.setVisible(true);
}

////////////////////////////////////////////////////
// fullscreen across multiple displays: method #2 //
////////////////////////////////////////////////////

// NOTE: this method DOES NOT work on Showcase Linux machines
// overwrite PApplets init method to set the frame to undecorated=true 
/*public void init() 
{
    // to make a frame not displayable, you can use frame.removeNotify() 
    frame.removeNotify(); 
    frame.setUndecorated(true); 

    // addNotify, here i am not sure if you have to add notify again.   
    frame.addNotify(); 
    super.init();
}*/

void setup() 
{
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
    
    // make a new Client using mpe.ini file
    // sketchPath() is used so that the INI file is local to the sketch
    client = new TCPClient(iniPath, this);

    // the size is determined by the client's local width and height
    size(client.getLWidth(), client.getLHeight(), P3D);

    // fullscreen method #2: set the location of the undecorated frame
    //frame.setLocation(0, 0);

    //println("id: " + client.getID());
    // the random seed must be identical for all clients
    randomSeed(1);

    background(0);
    stroke(255);
    noCursor();

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

    // IMPORTANT, YOU MUST START THE CLIENT!
    client.start();
    
    // set field of view
    client.setFieldOfView(fov);
    
    // init perspective
    camera(cam[0], cam[1], cam[2], lookat[0], lookat[1], lookat[2], 0, 1, 0);
}

void draw() 
{
}

// Triggered by the client whenever a new frame should be rendered.
// All synchronized drawing should be done here when in auto mode.
void frameEvent(TCPClient c) 
{
    background(0);  
    // read any incoming messages
    if (c.messageAvailable()) {
        String[] msg = c.getDataMessage();
        String[] cl = msg[0].split(",");
        if (cl.length >= 6) {
            cam[0] = Float.parseFloat(cl[0]);
            cam[1] = Float.parseFloat(cl[1]);
            cam[2] = Float.parseFloat(cl[2]);
            lookat[0] = Float.parseFloat(cl[3]);
            lookat[1] = Float.parseFloat(cl[4]);
            lookat[2] = Float.parseFloat(cl[5]);
        }
    }
    camera(cam[0], cam[1], cam[2], lookat[0], lookat[1], lookat[2], 0, 1, 0);

    // draw world box
    noFill();
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(0, -25, 0);
    box(bounds, 50.0, bounds);
    popMatrix();
}

// load and parse sketch.ini file
void loadSketchFile(String fileString) 
{
    sketch_fp = new FileParser(fileString);
    
    if (sketch_fp.fileExists()) {          
        bounds = sketch_fp.getIntValue("bounds");
        if (bounds == -1) {
            bounds = 1000;
        }
        String fovID = "fov" + client.getID();
        fov = sketch_fp.getIntValue(fovID);
        if (fov == -1) {
            fov = 30;
        }       
    }
    else {
        bounds = 1000;
        fov = 30;  
    }
}
