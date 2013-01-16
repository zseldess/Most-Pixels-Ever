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

public class mpeClient extends PApplet {

// Render client for crosshair_test






// variables defined in sketch.ini file
float crosshair; // size of cursor crosshair in pixels
float[] mXY = new float[2]; // normalized mouseX and mouseY

// a client object
TCPClient client;
// stays false until all clients have connected
boolean start = false;

// object to parse sketch.ini
FileParser sketch_fp;

////////////////////////////////////////////////////
// fullscreen across multiple displays: method #1 //
////////////////////////////////////////////////////
// NOTE: this method works on Showcase Linux machines and on OSX

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

    // parse mpe.ini, get localScreenSize field
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

// NOTE: this method DOES NOT work on Showcase Linux machines (sun jdk vs open-jdk?)
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

public void setup() 
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
    client = new TCPClient(sketchPath("mpe.ini"), this);
    
    // the size is determined by the client's local width and height
    size(client.getLWidth(), client.getLHeight());
    
    // fullscreen method #2: set the location of the undecorated frame
    //frame.setLocation(0, 0);

    //println("id: " + client.getID());
    // the random seed should be identical for all clients
    randomSeed(1);

    background(0);
    noFill();
    stroke(255);
    strokeWeight(3);
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
}

public void draw() 
{
}

// Triggered by the client whenever a new frame should be rendered.
// All synchronized drawing should be done here when in auto mode.
public void frameEvent(TCPClient c) 
{           
    background(0); 
    // read any incoming messages
    if (c.messageAvailable()) {
        String[] msg = c.getDataMessage();
        String[] cl = msg[0].split(",");
        mXY[0] = Float.parseFloat(cl[0]);
        mXY[1] = Float.parseFloat(cl[1]);
        
        mXY[0] *= PApplet.parseFloat(client.getMWidth());
        mXY[1] *= PApplet.parseFloat(client.getMHeight());
    }
    // draw crosshairs
    line(mXY[0]-(crosshair/2), mXY[1], mXY[0]+(crosshair/2), mXY[1]);
    line(mXY[0], mXY[1]-(crosshair/2), mXY[0], mXY[1]+(crosshair/2));
}

// load and parse sketch.ini file
public void loadSketchFile(String fileString) 
{
    sketch_fp = new FileParser(fileString);

    if (sketch_fp.fileExists()) {  
        crosshair = sketch_fp.getIntValue("crosshair");
        if (crosshair == -1) {
            crosshair = 50;
        }
    }
    else {
        crosshair = 50;
    }
}

}
