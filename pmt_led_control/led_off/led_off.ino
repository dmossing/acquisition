int pin_cam0 = 11;
int pin_led = 12;
int pin_pmt = 13;
int pin_test = 10;
int wait_time = 10000;
int period = 60;
static unsigned long t = 0;

boolean cam0 = false;
boolean old_cam0 = false;
boolean image2p = true;

void setup()
{
  pinMode(pin_cam0, INPUT);
  pinMode(pin_led, OUTPUT);
  pinMode(pin_pmt, OUTPUT);
  pinMode(pin_test, OUTPUT);
  digitalWrite(pin_pmt, LOW);
  digitalWrite(pin_led, LOW);
}

void loop()
{
}
