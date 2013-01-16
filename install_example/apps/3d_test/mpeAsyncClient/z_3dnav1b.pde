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
float cam[] = {0., 0., 0.}; // set camera coordinates
float lookat[] = {0., 0., 1.}; // set lookat coordinates
float lookYangle = PI * 0.5; // lookat angle constraints (PI == 180 degree rotation, PI*0.5 == 90 degrees)
// NOTE: setting lookYangle to PI or greater won't look good. I recommend not exceeding PI*0.9
float easing = 0.1; // set smoothing (0.01 == very smooth, 1. == no smoothing)
float dragSpeed = 0.5; // set rotation speed
int mouseTerritory[] = new int[2]; // the pixel boundaries of the cursor

int speedKey = 0; // 0 sets SPACEBAR as speedKey, 1 sets SHIFT as speedKey
float speedXZ = 0.5; // adjust speed along x/z plane (when using w/s/a/d keys)
float speedY = 0.1; // adjust speed along y axis (when using r/e keys)
float fSpeedXZ = 5.0; // adjust fast speed along x/z plane (when using w/s/a/d keys)
float fSpeedY = 2.5; // adjust fast speed along y axis (when using r/e keys)
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
void navSetup() {
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
void checkScreenSize() {
    if (sizeX >= mouseTerritory[0]) {
        sizeX = mouseTerritory[0];
    }
    if (sizeY >= mouseTerritory[1]) {
        sizeY = mouseTerritory[1];
    }
}

void deriveCursor() {
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
        Ymouse = float(sizeYedge);
        println("lookat vector exceeds bounds of specified lookYangle: " + lookYangle);
        println("constraining lookat accordingly...");
    }
    if (Ymouse > sizeY-sizeYedge) {
        Ymouse = float(sizeY-sizeYedge);
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
void keyPressed() {
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

void keyReleased() { 
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

void navUpdate() {
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

void mouseTrack() {
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

void mouseEase() {  
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

void checkDirection() {
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

void checkRotation() {
    mX = ((easeX-sizeXedge)/float(sizeX-(sizeXedge*2)))*TWO_PI; // scale mouseX movement between 0 and 2*PI
    mY = ((easeY-sizeYedge)/float(sizeY-(sizeYedge*2)))*lookYangle - lookYangle/2;
    lookat[0] = cam[0] + cos(mX)*cos(mY);
    lookat[1] = cam[1] + sin(mY);
    lookat[2] = cam[2] + sin(mX)*cos(mY);
}

void translateForward() {
    cam[0] = cam[0] + (cos(mX) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX) * currentSpeedXZ);
}

void translateBackward() {
    cam[0] = cam[0] + (cos(mX-PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-PI) * currentSpeedXZ);
}

void translateLeft() {
    cam[0] = cam[0] + (cos(mX-HALF_PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-HALF_PI) * currentSpeedXZ);
}

void translateRight() {
    cam[0] = cam[0] + (cos(mX+HALF_PI) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+HALF_PI) * currentSpeedXZ);
}

void translateForwardLeft() {
    cam[0] = cam[0] + (cos(mX-(PI*0.25)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-(PI*0.25)) * currentSpeedXZ);
}

void translateForwardRight() {
    cam[0] = cam[0] + (cos(mX+(PI*0.25)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+(PI*0.25)) * currentSpeedXZ);
}

void translateBackwardLeft() {
    cam[0] = cam[0] + (cos(mX-(PI*0.75)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX-(PI*0.75)) * currentSpeedXZ);
}

void translateBackwardRight() {
    cam[0] = cam[0] + (cos(mX+(PI*0.75)) * currentSpeedXZ);  
    cam[2] = cam[2] + (sin(mX+(PI*0.75)) * currentSpeedXZ);
}

void translateUp() {
    cam[1] -= currentSpeedY;
}

void translateDown() {
    cam[1] += currentSpeedY;
}
//--------------------------------------//

