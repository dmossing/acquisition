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
}

void loop()
{
  cam0 = digitalRead(pin_cam0);
//  t = millis();
//  cam0 = ((t % period) < period/2);
  digitalWrite(pin_cam0, cam0);
  digitalWrite(pin_test, image2p);
  if (cam0 && !old_cam0)
  {
    if (image2p)
    {
      digitalWrite(pin_led, LOW);
      delayMicroseconds(wait_time);
      digitalWrite(pin_pmt, HIGH);
    }
    else
    {
      digitalWrite(pin_pmt, LOW);
      delayMicroseconds(wait_time);
      digitalWrite(pin_led, HIGH);
    }
    image2p = !image2p;
  }
  old_cam0 = cam0;
}
