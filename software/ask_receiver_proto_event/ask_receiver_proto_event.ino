// -*- mode: C++ -*-
// Using RadioHead to receive messages
// Implements a simplex (one-way) ASK receiver 

#include <RH_ASK.h>
#include <SPI.h> // Not actualy used but needed to compile

RH_ASK radio(2400,8,12,10);
//baud, rx, tx, ptt

//buffer is global
uint8_t buf[RH_ASK_MAX_MESSAGE_LEN];
uint8_t mlen = RH_ASK_MAX_MESSAGE_LEN;

const int winsize = 5; // winsize for smoothing
const int nsensor = 4; // number of sensors connected A0 through A7
int window[winsize*nsensor]; // main array to hold readings
int total[nsensor];          // totals array for fast smoothing

int s = 0; // sensor index
int t = 0; // time index
int i ; // convenience index
int inByte;

void setup()
{
    Serial.begin(57600);	// Debugging only
    if (!radio.init())
         Serial.println("init failed");
  //  else 
  //        Serial.println(RH_ASK_MAX_MESSAGE_LEN);

    // wait for serial to send something. 
    
    while (Serial.available() <= 0) {
      Serial.print('*');
      delay(200);
    }
}

void loop() {
  for ( s=0; s<nsensor; s ++) {
     i= s*winsize+t;
     total[s] -= window[i];
     window[i] = analogRead(s);
     total[s] += window[i];
  }
}
void serialEvent()
{
    digitalWrite(13,HIGH);
    
    // get incoming byte:
    Serial.read();
    
    while (!radio.recv(buf, &mlen)) {
      
      //keep scanning until packet available
      
      for ( s=0; s<nsensor; s ++) {
        i= s*winsize+t;
        total[s] -= window[i];
        window[i] = analogRead(s);
        total[s] += window[i];
      }
    t = (t+1)%winsize;
    }
    
    // Message with a good checksum received, dump it.
    analogWrite(6, buf[0]);
    for (s=0; s<nsensor; s++){
    //    Serial.print(String(buf[s]));
    //    Serial.print('\t');
        // push s'th sensor of other foot
        Serial.write(buf[s]); 
        //push s'th sensor of this foot
        Serial.write((uint8_t) map( total[s]/winsize , 0, 1023, 0, 255));
      }
     // Serial.print(String(window[0]));
     // Serial.print('\n');
    digitalWrite(13,LOW);
  
}

