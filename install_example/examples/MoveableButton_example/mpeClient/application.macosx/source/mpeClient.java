import processing.core.*; 
import processing.xml.*; 

import processing.opengl.*; 
import mpe.client.*; 
import mpe.config.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class mpeClient extends PApplet {

// Client for Moveable Button example
//    In this example, the Client is dumb. It simply draws rectangles based on
//    the information it receives from AsyncClient. Drawing order is determined 
//    by the order of the message contents. No decisions made by this client.



//########## START MPE STUFF ##########//
// required for all MPE applications



// client object
TCPClient client;
// stays false until all clients have connected
boolean start = false;

// object to parse sketch.ini
FileParser sketch_fp;
//########## END MPE STUFF ##########//

//########## START MPE STUFF ##########//    
static public void main(String argv[]) 
{   
    // The rest of main() handles setting the window to fullscreen across multiple displays
    // Don't change this, unless you know what you're doing
    Frame frame = new Frame("testing");
    frame.setUndecorated(true);
    PApplet applet = new mpeClient();
    frame.add(applet);
    applet.init();

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
//########## END MPE STUFF ##########//

public void setup() 
{    
    //########## START MPE STUFF ##########//
    String iniPath = "";
    // get path of mpe.ini 
    // NOTE: this only works when running as application
    // When running as sketch, get path as follows
    iniPath = sketchPath("mpe.ini");    
    /*File directory = new File (".");
    try {
        iniPath = directory.getCanonicalPath() + "/mpe.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }*/

    // make a new Client using mpe.ini file
    client = new TCPClient(iniPath, this);
    //println("id: " + client.getID());

    // set window size and renderer
    // the size is determined by the client's local width and height
    size(client.getLWidth(), client.getLHeight(), OPENGL);

    // get path of sketch.ini
    // NOTE: this only works when running as application
    // when running as sketch, get path this way
    iniPath = sketchPath("sketch.ini");    
    /*iniPath = "";
    try {
        iniPath = directory.getCanonicalPath() + "/sketch.ini";
    }
    catch(Exception e) {
        //System.out.println("Exceptione is ="+e.getMessage());
    }*/

    // parse sketch.ini file
    loadSketchFile(iniPath);
      
    // IMPORTANT, YOU MUST START THE CLIENT!
    client.start();
    
    // random/noise seeds must be identical for all clients... 
    // if you want the results to be the same
    randomSeed(1);
    noiseSeed(1);
    //########## END MPE STUFF ##########//
    
    // set initial background color
    background(0); 
    // set intitial stroke color
    strokeWeight(2);
    // hide cursor
    noCursor();
    // don't use fill for buttons
    noFill();
    
    // some OPENGL optimizations
    //hint(DISABLE_OPENGL_ERROR_REPORT);
    //hint(DISABLE_OPENGL_2X_SMOOTH);
}

public void draw() 
{
    // This is where you normally do your work in Processing sketches.
    // We'll use frameEvent() instead for mpe applications.
    // Leave draw() here to keep the engine going though.
}

// Triggered by the client whenever a new frame should be rendered.
// All synchronized drawing should be done here when in auto mode.
public void frameEvent(TCPClient c) 
{    
    // read any incoming messages
    if (c.messageAvailable()) {
        // grab and store as in array of strings (we're only using the first element)
        String[] msg = c.getDataMessage();
        // split first element into array based on commas
        String[] cl = msg[0].split(",");
        
        // clear the screen
        background(0);
        
        // use the new information
        // NOTE: You have to convert them from a String to whatever data 
        // type they originally were before the AsyncClient sent them
        for (int i = 0; i <= cl.length-7; i+=7) {
            // set stroke color
            stroke(Integer.parseInt(cl[i+4]), Integer.parseInt(cl[i+5]), Integer.parseInt(cl[i+6]));
            // draw button
            rect(Float.parseFloat(cl[i]), Float.parseFloat(cl[i+1]), Float.parseFloat(cl[i+2]), Float.parseFloat(cl[i+3]));
        }
    }
}

// Nothing to load from sketch.ini in render clients, but I've left this here for reference
// load and parse sketch.ini file
public void loadSketchFile(String fileString) 
{
    sketch_fp = new FileParser(fileString);
    /*
    if (sketch_fp.fileExists()) {  
        cSize = sketch_fp.getIntValue("cursorSize");
        if (cSize == -1) {
            cSize = 50;
        }

        // grab other application-specific fields from sketch.ini...
        
        // example methods for supported data types:
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
    }
    else {
        cSize = 50;
    }*/
}

}
