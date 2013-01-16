// AsyncClient for Moveable Button example
//    In this example, the AsyncClient has all the "brains". 
//    Render clients simply draw rectangles based on the AsyncClients messages.

import processing.opengl.*;

//########## START MPE STUFF ##########//
// required for all MPE applications
import mpe.client.*;
import mpe.config.*;

// async client object
AsyncClient client;
// objects to parse sketch.ini, mpe.ini
FileParser sketch_fp, mpe_fp;

// variables defined in mpe.ini file
String serverIP; // server ip

// variables defined in sketch.ini file
int asyncPort; // AsyncClient backdoor port on server (9003 in mpe script)
int asyncFPS; // AsyncClient framerate (60 in mpe script)

String clientMess; // string to send to clients
boolean firstRelease; // boolean to track when mouse is first released
//########## END MPE STUFF ##########//

Button[] b = new Button[10]; // use a ArrayList instead for variable sizing
int[] order = new int[b.length]; 
float minSize = 30.0;
float maxSize = 100.0;
float zoomScale = 2.0;

void setup() {
    size(640, 480, OPENGL);
    background(0);
    strokeWeight(2); 
    initButtons();
    
    // some OPENGL optimizations
    hint(DISABLE_OPENGL_ERROR_REPORT);
    hint(DISABLE_OPENGL_2X_SMOOTH);
        
    //########## START MPE STUFF ##########//
    String iniPath = "";
    // get path of mpe.ini 
    // NOTE: this only works when running as application
    // When running as sketch, get path as follows
    //iniPath = sketchPath("mpe.ini");
    File directory = new File (".");
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

    // set framerate
    frameRate(asyncFPS);

    // make a new Client using ip and listening port of server
    client = new AsyncClient(serverIP, asyncPort);
    //########## END MPE STUFF ##########//
}

void draw() {
    background(0);
    if (buttonEvent != -1 && mouseButton == LEFT) {
        b[buttonEvent].x_pos += mouseX - pmouseX;
        b[buttonEvent].y_pos += mouseY - pmouseY;
    }  
    else if (buttonEvent != -1 && mouseButton == RIGHT) {
        b[buttonEvent].w += (mouseX - pmouseX) * zoomScale;
        b[buttonEvent].x_pos += ((pmouseX - mouseX) * zoomScale) * 0.5;        
        b[buttonEvent].h = b[buttonEvent].w * b[buttonEvent].aspect;
        b[buttonEvent].y_pos += ((pmouseX - mouseX) * zoomScale) * (b[buttonEvent].aspect * 0.5);           
    }    
    for (int i = 0; i < b.length; i++) {
        b[order[i]].checkStatus();
    }
    for (int i = b.length-1; i >= 0; i--) {
        b[order[i]].display();
    }
    setOrder();

    //########## START MPE STUFF ##########//
    // if mousePressed and button is selected, send data to clients
    if (mousePressed && (buttonEvent != -1)) {
        sendToClients();
        firstRelease = true;
    }
    // also send data when button is deselected
    else if (!mousePressed && (buttonEvent == -1) && firstRelease) {
        sendToClients();
        firstRelease = false;
    }
    //########## END MPE STUFF ##########//
}

void initButtons() {
    for (int i=0; i < b.length; i++) {
        b[i] = new Button(random(minSize, maxSize), random(minSize, maxSize), random(width), random(height), i);
        order[i] = i;
    }
}

void setOrder() {
    //println(buttonEvent);
    for (int i = 1; i <= order.length-1; i++) {
        if (buttonEvent == order[i]) {
            for (int j = i; i > 0; i--) {
                order[i] = order[i-1];
            }
            order[0] = buttonEvent;
            //println(order);
        }
    }
}

//########## START MPE STUFF ##########//
void sendToClients() {    
    // send data to mpe clients for drawing (for this example, data sent every frame... which is wasteful)
    /* send to clients (on large string, with elements separated by commas):
        1. b[order[0]] x, y, w, h, r, g, b 
        2. b[order[1]] x, y, w, h, r, g, b
        3. and so on for all buttons....
    */
    // look at StringBuffer and StringBuilder classes for more efficient way of doing this
    clientMess = b[order[b.length-1]].x_pos + "," + b[order[b.length-1]].y_pos + "," + b[order[b.length-1]].w + "," + b[order[b.length-1]].h + "," + b[order[b.length-1]].currentColor[0] + "," + b[order[b.length-1]].currentColor[1] + "," + b[order[b.length-1]].currentColor[2];  
    for (int i = b.length-2; i >= 0; i--) {
        clientMess = clientMess + "," + b[order[i]].x_pos + "," + b[order[i]].y_pos + "," + b[order[i]].w + "," + b[order[i]].h + "," + b[order[i]].currentColor[0] + "," + b[order[i]].currentColor[1] + "," + b[order[i]].currentColor[2];
    }
    //println(client_mess);
    client.broadcast(clientMess); 
    //########## END MPE STUFF ##########// 
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
    }
}
//########## END MPE STUFF ##########//

