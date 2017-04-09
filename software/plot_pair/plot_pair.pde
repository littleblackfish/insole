/**
 * Read pressure data from arduino and make a rough plot of sensing points 
 * radius of circles are proportional to the pressure
 */

import processing.serial.*;
import static javax.swing.JOptionPane.*;

Serial myPort;                 // Create object from Serial class
boolean firstContact = false;  // have we heard from the microcontroller yet?

int nsensor = 8;
int winSize = 100; 

byte[][] SerialValue = new byte[winSize][2*nsensor]; //raw sensor values
float[][]right =  new float[winSize][nsensor/2];
float[][] left  = new float[winSize][nsensor/2];
float[][] center = new float[winSize][2];

//sensor positions
int[] leftX  = {233,245,155,200};
int[] leftY  = {95,185,185,505};
int[] rightX = {800-leftX[0],800-leftX[1],800-leftX[2], 800-leftX[3]};
int[] rightY = leftY;

float mult = 0.5; //radius multiplier

int t=0;

void setup() {
  String COMx, COMlist = "";

  size(800, 600);
  int baud = 57600;
  //printArray(Serial.list());
  try {
    int i = Serial.list().length;
    if (i != 0) {
      if (i >= 2) {
        // need to check which port the inst uses -
        // for now we'll just let the user decide
        for (int j = 0; j < i;) {
          COMlist += char(j+'a') + " = " + Serial.list()[j];
          if (++j < i) COMlist += "\n  ";
        }
        COMx = showInputDialog("Which serial port?\n"+COMlist);
        if (COMx == null) exit();
        if (COMx.isEmpty()) exit();
        i = int(COMx.toLowerCase().charAt(0) - 'a') + 1;
      }
      String portName = Serial.list()[i-1];
      myPort = new Serial(this, portName, baud); 
      myPort.buffer(1);
    }
    else {
      showMessageDialog(frame,"No serial ports available");
      exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame,"Port is not available.");
    println("Error:", e);
    exit();
  }
}
void draw() {
      //old debug code
    clear();
    float totalP=0;
    float weight;
    
    // plot the fresh data    
    fill(color(50, 50, 100));
    for (int i = 0; i < nsensor/2; i = i+1) {
       ellipse(rightX[i],rightY[i], right[t][i], right[t][i] ); 
       ellipse(leftX[i] , leftY[i], left[t][i] , left [t][i] ); 
       
       // modify weigh for sensors 1 and 2
       if (i==1 || i==2) weight=0.5;
       else weight = 1 ;
       
       center[t][0] += (rightX[i]*right[t][i] + leftX[i]*left[t][i]) *weight;
       center[t][1] += (rightY[i]*right[t][i] + leftY[i]*left[t][i]) *weight;
       totalP += (right[t][i]+left[t][i])*weight;
    }
    
    //plot center point
    center[t][0]/=totalP;
    center[t][1]/=totalP;
    fill(color(100, 0, 0));
    ellipse(center[t][0], center[t][1], totalP/nsensor, totalP/nsensor );
}

void serialEvent(Serial myPort) {
  
  if (firstContact == false) {  // if this is the first contact 
    int inByte = myPort.read(); // read a single byte from the serial port
    if (inByte == '*') {        // it's an *
      myPort.clear();           // clear the serial port buffer
      firstContact = true;      // you now had first contact from the microcontroller
      
      myPort.buffer(nsensor);
      myPort.write('*');        // ask for more
      t = 0;
    }
    println("Shook hands with the controller");
  }
  
  else {
   // println("reading!");
    t = (t+1)%winSize;
    int byteCount = myPort.readBytes(SerialValue[t]); //read the next nsensor bytes
    
    if (byteCount == nsensor) {
     
      // map raw byte readings to sensor values
      for (int i = 0; i < nsensor/2; i = i+1) {
        right[t][i] = (float)  (SerialValue[t][2*i] & 0xff);      
        left [t][i]  = (float) (SerialValue[t][(2*i)+1] & 0xff) ;
        right[t][i]*=mult;
        left[t][i]*=mult;
      }
    }
    else {
      println("skipped a frame for some reason");
    }
  //  for (int i =0; i<nsensor; i++) print(SerialValue[t][i], ' ');
  //  print('\n');
  //  for (int i =0; i<nsensor/2; i++) print(right[t][i], ' ');
  //  print('\n');
    
    myPort.write('*');        // Ask for the next frame
    }
  }

//stop the serial port
void stop() {
  myPort.stop();
}

//reset communication by pressing r
void keyPressed() {
  if (key == 'r') {
      firstContact = false;      // you now had first contact from the microcontroller
      t=0;
      myPort.clear();           // clear the serial port buffer
      myPort.buffer(1); 
      println("Reset!");
  }
}