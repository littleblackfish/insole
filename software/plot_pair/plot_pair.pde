/**
 * Read pressure data from arduino and make a rough plot of sensing points 
 * radius of circles are proportional to the pressure
 */

import processing.serial.*;
import static javax.swing.JOptionPane.*;

Serial myPort;                 // Create object from Serial class
boolean firstContact = false;  // have we heard from the microcontroller yet?

final int nsensor = 8;      //number of sensors
final int bufSize = 1000;   //buffer size limits max window size

final int shortWin = 3;   // fastest motion maps to vertical radius
final int medWin   = 6;    // slower motion maps to horizontal radius
final int longWin  = 50;  // slowest motion maps to color
final int trailSize = 50;
final int centerWin = 4;

//sensor positions
final int[] leftX  = {233,245,155,200};
final int[] leftY  = {95,185,185,505};
final int[] rightX = {800-leftX[0],800-leftX[1],800-leftX[2], 800-leftX[3]};
final int[] rightY = leftY;

final color red = color(255, 0, 0);
final color blue = color(0,0,255);
    
byte[][] rawRead = new byte[bufSize][2*nsensor]; //raw sensor readings as read from serial
float[][] right =  new float[bufSize][nsensor/2];
float[][] left  = new float[bufSize][nsensor/2];
float[][] center = new float[bufSize][2];

float[] shortSumL = new float[nsensor/2];
float[] shortSumR = new float[nsensor/2];
float[] medSumL = new float[nsensor/2];
float[] medSumR = new float[nsensor/2];
float[] longSumL = new float[nsensor/2];
float[] longSumR = new float[nsensor/2];
float[][] centerSum = new float[bufSize][2];

float[] totalP = new float[bufSize];

float mult = 0.5; //radius multiplier

int t=0;

void setup() {
  noLoop();
  String COMx, COMlist = "";

  size(800, 600);
  background(125);
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
    clear();
    background(125);


    // plot the fresh data    
    noStroke();
    for (int i = 0; i < nsensor/2; i = i+1) {
       fill(lerpColor(blue,red,longSumL[i]/(longWin*128)));
       ellipse(leftX[i] , leftY[i], medSumL[i]/medWin, shortSumL[i]/shortWin ); 
       fill(lerpColor(blue,red,longSumR[i]/(longWin*128)));
       ellipse(rightX[i],rightY[i], medSumR[i]/medWin, shortSumR[i]/shortWin ); 
    }
    
    fill(255,255,255);
    text(frameRate, 20,20);
    
    //track the center with a curve
    noFill();  
    stroke(color(0, 255, 0));
    strokeWeight(3);
    beginShape();
    curveVertex(centerSum[(t-trailSize+bufSize)%bufSize][0]/centerWin, centerSum[(t-trailSize+bufSize)%bufSize][1]/centerWin);
    for (int i = (t-trailSize+bufSize)%bufSize ;  i<=t ; i++) {
      curveVertex(centerSum[i][0]/centerWin, centerSum[i][1]/centerWin);
    //  stroke(color(t-i));

    }
    curveVertex(centerSum[t][0]/centerWin, centerSum[t][1]/centerWin);
    endShape();
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
      println("Shook hands with the controller");
    }
    
  }
  
  else {
 //   println("reading!");
    t = (t+1)%bufSize;
    int byteCount = myPort.readBytes(rawRead[t]); //read the next nsensor bytes
    
    if (byteCount == nsensor) {
      float weight;
      totalP[t] = 0;
     
      // map raw byte readings to sensor values
      for (int i = 0; i < nsensor/2; i = i+1) {
        left [t][i]  = (float) (rawRead[t][(2*i)+1] & 0xff) ;
        right[t][i] = (float)  (rawRead[t][2*i] & 0xff);      

        left[t][i]*=mult;
        right[t][i]*=mult;
        
        // modify weigh for sensors 1 and 2
        if (i==1 || i==2) weight=0.5;
        else weight = 1 ;
        //update center
        center[t][0] += (rightX[i]*right[t][i] + leftX[i]*left[t][i]) *weight;
        center[t][1] += (rightY[i]*right[t][i] + leftY[i]*left[t][i]) *weight;
        totalP[t] += (right[t][i]+left[t][i])*weight;
        
        //update moving averages
        shortSumR[i] += right[t][i] - right[(t+bufSize-shortWin)%bufSize][i];
        shortSumL[i] += left[t][i] - left[(t+bufSize-shortWin)%bufSize][i];
        medSumR[i] += right[t][i] - right[(t+bufSize-medWin)%bufSize][i];
        medSumL[i] += left[t][i] - left[(t+bufSize-medWin)%bufSize][i];
        longSumR[i] += right[t][i] - right[(t+bufSize-longWin)%bufSize][i];
        longSumL[i] += left[t][i] - left[(t+bufSize-longWin)%bufSize][i];
      }
      
      center[t][0]/=totalP[t];
      center[t][1]/=totalP[t];
      totalP[t]/=nsensor;
      
      centerSum[t][0] = centerSum[(t+bufSize-1)%bufSize][0]+ center[t][0] - center[(t+bufSize-centerWin)%bufSize][0];
      centerSum[t][1] = centerSum[(t+bufSize-1)%bufSize][1]+ center[t][1] - center[(t+bufSize-centerWin)%bufSize][1];
      
      //draw fresh data
      redraw();
    }

    else {
      println("skipped a frame for some reason");
    }
  //  for (int i =0; i<nsensor; i++) print(rawRead[t][i], ' ');
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