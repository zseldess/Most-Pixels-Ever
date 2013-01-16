int buttonEvent = -1;

public class Button { // GUI button class
    float aspect;
    float x_pos;
    float y_pos;
    float w;
    float h;
    int id;
    boolean pressed = false; 
    int[] activeColor = {255, 255, 255};
    int[] inactiveColor = {100, 100, 100};
    int[] currentColor = {100, 100, 100};
    boolean report = true; // turns reporting on/off

    Button (float wdth, float hgth, float X, float Y, int ident) {
        x_pos = X;
        y_pos = Y;
        w = wdth;
        h = hgth;
        aspect = h/w;
        id = ident;
    }

    void display() {
        if (buttonEvent == id) currentColor = activeColor;
        else currentColor = inactiveColor;
        stroke(currentColor[0], currentColor[1], currentColor[2]);
        noFill();
        rect(x_pos, y_pos, w, h);
    }
    
    void checkStatus() {
        if (mouseX >= x_pos && mouseX <= x_pos+w && mouseY >= y_pos && mouseY <= y_pos+h) {
            if (mousePressed && (buttonEvent == -1 || buttonEvent == id) ) {
                buttonEvent = id;
                pressed = true;
            }
        }
        if (!mousePressed) {
            buttonEvent = -1;
            pressed = false;
        }
    }
    
}

