//Code specific for Arduino Mega 2560
// PORTE 4 is line 2
// PORTH 0 is line 17

int fullPeriod = 66;
int onTime = 16;

int offTime = 8;
int interTime = 50;

void setup() {
  // put your setup code here, to run once:
DDRE = B11111100;        //Pin 1 of PORTD is an input, all others are outputs
DDRH = B00000000;        //Pin 1 of PORTD is an input, all others are outputs


DDRH = B00000000; 
PORTH = B11111111; 

noInterrupts();

}

void loop() {
  
if ((PINH & (B00000001))==1){
  PORTE = (1<<PD4);    //Pin 2 of portd as now the logic value 1
  delayMicroseconds(10); //16
  PORTE = (0<<PD4);    //Pin 2 of portd as now the logic value 0
  delayMicroseconds(38); //34
  PORTE = (1<<PD4);    //Pin 2 of portd as now the logic value 1
  delayMicroseconds(30); //32
  PORTE = (0<<PD4);    //Pin 2 of portd as now the logic value 0
  delayMicroseconds(38);  //34
  PORTE = (1<<PD4);    //Pin 2 of portd as now the logic value 1
}

}
