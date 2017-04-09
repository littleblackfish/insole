// -*- mode: C++ -*-
// Using RadioHead to transmit messages
// Implements a simplex (one-way) ASK transmitter 

#include <RH_ASK.h>
#include <SPI.h> // Not actually used but needed to compile

RH_ASK radio(2400,11,12,10);
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
int i ;    // convenience index

void setup()
{
    Serial.begin(9600);	  // Debugging only
    if (!radio.init())
         Serial.println("init failed");
    
    pinMode(13, OUTPUT);
    
    //initialize everything with zeros
    for ( i=0; i< winsize*nsensor; i++ ) window[i]=0;
    for (i=0; i<nsensor;i++) total[i] = 0; 
}

void loop()
{   
    for ( s=0; s<nsensor; s ++) {
      i= s*winsize+t;
      total[s] -= window[i];
      window[i] = analogRead(s);
      total[s] += window[i];
    }
    t = (t+1)%winsize;

    for ( s=0; s<nsensor; s ++) { 
      buf [s] = (uint8_t) map( total[s]/winsize , 0, 1023, 0, 255);
    }

   // for (s=0; s<nsensor; s++) 
    analogWrite(6, buf[0]);
      
    //for (s=0; s<nsensor; s++){
    //    Serial.print(buf[s]);
    //    Serial.print('\t');
    //  }
    //Serial.print('\n');
    
    digitalWrite(13,HIGH);
    radio.send(buf, nsensor);
    radio.waitPacketSent();
    digitalWrite(13,LOW);
    

}
