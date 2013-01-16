// AsyncClient Template

// required for all MPE applications
import mpe.client.*;
import mpe.config.*;
// required if using OpenGL
import processing.opengl.*;

// arguments passed in via command-line
static String[] args;

// async client object
AsyncClient client;
// objects to parse sketch.ini, mpe.ini
FileParser sketch_fp, mpe_fp;

// variables defined in mpe.ini file
String serverIP; // server ip

// variables defined in sketch.ini file
int asyncPort; // AsyncClient backdoor port on server (9003 in mpe script)
int asyncFPS; // AsyncClient framerate (60 in mpe script)
float fov; // field of view (degrees)

// async client window size
int[] winSize = {1000, 226};

static public void main(String argv[]) 
{
    args = argv.clone();
    PApplet.main(new String[] { "mpeAsyncClient" });
}

void setup() 
{
    // set window size and renderer
    size(winSize[0], winSize[1], OPENGL);
    // if you want to be able to resize the window
    frame.setResizable(true); 
    // set initial background color
    background(0); 
    // set intitial stroke color
    stroke(255);

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
    
    // parse mpe.ini file
    loadMpeFile(iniPath);

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

    // set framerate
    frameRate(asyncFPS);
    
    // init perspective (cameraZ and fov setup here same as in MPE)
    float cameraZ = ((height/2.0) / tan(PI * fov/360.0));
    perspective(((fov/180.0) * PI), float(width)/float(height), cameraZ/100.0, cameraZ*10.0); // args 3-4 near/far clip

    // make a new Client using ip and listening port of server
    client = new AsyncClient(serverIP, asyncPort);
}

void draw() 
{
    // clear the screen     
    background(0);

    // on window resize:
    // update winSize[0] and winSize[1] to make the perspective stay constant
    // comment them out to skew the viewport to match the aspect ratio of total mpe window size    
    if (width != winSize[0] || height != winSize[1]) {
        //winSize[0] = width;
        //winSize[1] = height;
        float cameraZ = ((height/2.0) / tan(PI * fov/360.0));
        perspective(((fov/180.0) * PI), float(winSize[0])/float(winSize[1]), cameraZ/100.0, cameraZ*10.0); // args 3-4 near/far clip      
    }

    // send data to mpe clients (for this example, data sent only when mouse pressed)
    if (mousePressed) {        
        client.broadcast((float)mouseX/(float)width + "," + (float)mouseY/(float)height);
        //println((float)mouseX/(float)width + "," + (float)mouseY/(float)height);
    }
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
        asyncPort = 9003;
        asyncFPS = 30;
        fov = 30;
    }
}

// do something with command-line arguments, if desired...
void parseArgs()
{
    //...
}

