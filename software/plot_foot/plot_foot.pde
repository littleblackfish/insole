/**
 * Resad pressure data from arduino and make a rough plot of sensing points 
 * radius of circles are proportional to the pressure
 * I will color code this later on. 
 */


import processing.serial.*;

Serial myPort;                 // Create object from Serial class
boolean firstContact = false;  // have we heard from the microcontroller yet?
int serialCount = 0;           // how many bytes we received
int[] sensor  = new int[5];    // array to keep data from sensors

void setup() 
{
  size(400, 700);
  //open (first) serial port
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
}

void draw()
{
  int radius;

  clear();
 // for (int i =0; i<5; i++) sensor[i]=100;
  for (int i =0; i<5; i++) print(sensor[i], ' ');
  print('\n');

  ellipse(125,100, sensor[0],sensor[0] );
  ellipse(100,250, sensor[1],sensor[1] );
  ellipse(300,250, sensor[2],sensor[2] );
  ellipse(200,400, sensor[3],sensor[3] );
  ellipse(200,600, sensor[4],sensor[4] );
 }

void serialEvent(Serial myPort) {

  // read a byte from the serial port:
  int inByte = myPort.read();
  if (firstContact == false) { // if this is the first contact 
    if (inByte == 'A') {       // and it's an A
      myPort.clear();          // clear the serial port buffer
      firstContact = true;     // you now had first contact from the microcontroller
      myPort.write('A');       // ask for more
    }
    println("First contact with the microcontroller !");
  }
  else {
    // Add the latest byte from the serial port to array:
    sensor[serialCount] = inByte;
    serialCount++;
    
    if (serialCount >= 5 ) {    // if you already had 5 readings
      myPort.write('A');        // Send 'A' to request new sensor readings:
      serialCount = 0;          // start over for a new set of readings
    }
  }
}