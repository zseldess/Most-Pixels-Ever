/**
 * Crazy Flocking 3D Birds
 * by Ira Greenberg. MPE port by Zachary Seldess
 * 
 * Simulates a flock of birds using a Bird class and nested
 * pushMatrix() / popMatrix() functions. 
 * Trigonometry functions handle the flapping and sinuous movement.
 */

// required for all MPE applications
import mpe.client.*;
import mpe.config.*;
// required if using OpenGL
import processing.opengl.*;

// arguments passed in via command-line
static String[] args;

// client object
TCPClient client;
// stays false until all clients have connected
boolean start = false;

// object to parse sketch.ini
FileParser sketch_fp;

// variables defined in sketch.ini file
float fov; // field of view (degrees)
int birdCount; // number of birds;

Bird[] birds;
float[] x;
float[] y;
float[] z;
float[] rx;
float[] ry;
float[] rz;
float[] spd;
float[] rot;


static public void main(String argv[]) 
{
    args = argv.clone();
    
    // The rest of main() handles setting the window to fullscreen across multiple displays
    // Don't change this, unless you know what you're doing
    Frame frame = new Frame("testing");
    frame.setUndecorated(true);
    PApplet applet = new mpeClient();
    frame.add(applet);
    applet.init();

    // get path of mpe.ini 
    // NOTE: this only works when running as application
    // When running as sketch, get path as follows
    //iniPath = sketchPath("mpe.ini");
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

    // set frame size from localScreenSize array (in mpe.ini)
    frame.setBounds(0, 0, winXY[0], winXY[1]); 
    frame.setVisible(true);
}

void setup() 
{
    // get path of mpe.ini 
    // NOTE: this only works when running as application
    // When running as sketch, get path as follows
    //iniPath = sketchPath("mpe.ini");    
    File directory = new File (".");
    String iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/mpe.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }

    // make a new Client using mpe.ini file
    client = new TCPClient(iniPath, this);
    //println("id: " + client.getID());

    // set window size and renderer
    // the size is determined by the client's local width and height
    size(client.getLWidth(), client.getLHeight(), OPENGL);

    // get path of sketch.ini
    // NOTE: this only works when running as application
    // when running as sketch, get path this way
    //iniPath = sketchPath("sketch.ini");    
    iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/sketch.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }

    // parse sketch.ini file
    loadSketchFile(iniPath);
    
    // random/noise seeds must be identical for all clients... 
    // if you want the results to be the same
    randomSeed(1);
    noiseSeed(1);
    
    // parse command-line arguments
    parseArgs();
     
    // set initial background color
    background(0); 
    // set intitial stroke state
    noStroke();
    // hide cursor
    noCursor();  
  
    // Initialize Flock array
    birds = new Bird[birdCount];
    x = new float[birdCount];
    y = new float[birdCount];
    z = new float[birdCount];
    rx = new float[birdCount];
    ry = new float[birdCount];
    rz = new float[birdCount];
    spd = new float[birdCount];
    rot = new float[birdCount];  
  
    // Initialize arrays with random values
    for (int i = 0; i < birdCount; i++){
        birds[i] = new Bird(random(-client.getMWidth()/2, client.getMWidth()/2), random(-client.getMHeight()/2, client.getMHeight()/2), random(-500, -2500), random(5, 30), random(5, 30)); 
        x[i] = random(20, 340);
        y[i] = random(30, 350);
        z[i] = random(1000, 4800);
        rx[i] = random(-160, 160);
        ry[i] = random(-55, 55);
        rz[i] = random(-20, 20);
        spd[i] = random(.1, 3.75);
        rot[i] = random(.025, .15);
    }  

    // IMPORTANT, YOU MUST START THE CLIENT!
    client.start();
    
    // set field of view
    client.setFieldOfView(fov);
}

void draw() 
{
    // This is where you normally do your work in Processing sketches.
    // We'll use frameEvent() instead for mpe applications.
    // Leave draw() here to keep the engine going though.
}

// Triggered by the client whenever a new frame should be rendered.
// All synchronized drawing should be done here when in auto mode.
void frameEvent(TCPClient c) 
{  
    // read any incoming messages
    if (c.messageAvailable()) {
        String[] msg = c.getDataMessage();
        String[] cl = msg[0].split(",");
        //...
    }
    
    // clear the screen
    background(0);
    
    // set default lighting
    lights();
    
    // animate flock
    for (int i = 0; i < birdCount; i++){
        birds[i].setFlight(x[i], y[i], z[i], rx[i], ry[i], rz[i]);
        birds[i].setWingSpeed(spd[i]);
        birds[i].setRotSpeed(rot[i]);
        birds[i].fly();
    }
}

// load and parse sketch.ini file
void loadSketchFile(String fileString) 
{
    sketch_fp = new FileParser(fileString);

    if (sketch_fp.fileExists()) {  
        birdCount = sketch_fp.getIntValue("birdCount");
        if (birdCount == -1) {
            birdCount = 200;
        }
        
        fov = sketch_fp.getIntValue("fov");
        if (fov == -1) {
            fov = 30;
        }

        // grab other application-specific fields from sketch.ini...
        
        // example methods for supported data types:
        /*******************************************
        // returns int (-1 if field not found)
        sketch_fp.getIntValue("someInt"));
        
        // returns float (-1.0 if field not found)
        sketch_fp.getFloatValue("someFloat"));
        
        // returns string (null if field not found)
        sketch_fp.getStringValue("somString"));
        
        // returns int[] ([-1,-1] if field not found)
        sketch_fp.getIntValues("someIntArray"));
        
        // returns float[] ([-1.0,-1.0]) if field not found
        sketch_fp.getFloatValues("someFloatArray"));
        
        // returns String[] ([null,null] if field not found)
        sketch_fp.getStringValues("someStringArray"));
        *******************************************/
    }
    else {
        birdCount = 200;
        fov = 30;
    }
}

// do something with command-line arguments...
void parseArgs()
{
    // if first argument provided, override fov variable
    if (args.length >= 1) {
        fov = constrain(Integer.parseInt(args[0]), 1, 180); 
    } 
}

