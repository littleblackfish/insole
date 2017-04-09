
/*
  AnalogReadSerial
  Reads an analog input on pin 0, prints the result to the serial monitor.
  Attach the center pin of a potentiometer to pin A0, and the outside pins to +5V and ground.

 This example code is in the public domain.
 */

#include <stdio.h>

int i, j;
int value[5];
int inByte;


// the setup routine runs once when you press reset:

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);  
  pinMode(13,OUTPUT);

  

  // send a byte to establish contact until receiver responds

  while (Serial.available() <= 0) {
    Serial.print('A');   // send a capital A
    delay(300);
  }
}

// the loop routine runs over and over again forever:

void loop() {

  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();


    // scan the sensors
    
    digitalWrite(13,HIGH);
    for (i=0; i<5 ; i++) 
    {
        value[i] = analogRead(i);
        delay(10);
    }
    digitalWrite(13,LOW);

    // send over serial
  
    for ( i=0; i<5; i++)
        Serial.write(value[i]/4);
    
    //Serial.println(value[4]);
    

  delay(10);        // delay in between reads for stability
  }

}
