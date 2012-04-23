int green = 5;
int amber = 6;
int red = 7;
int button = 3;

void setup() {
  pinMode(green, OUTPUT);
  pinMode(amber, OUTPUT);
  pinMode(red, OUTPUT);
  pinMode(button, INPUT);
}

void delayAmount() {
  if (digitalRead(button) == HIGH) {
    delay(125); 
  } else {
    delay(500);
  }
}

void sequence() {
  digitalWrite(red, LOW);
  digitalWrite(amber, LOW);
  digitalWrite(green, HIGH);
  delayAmount();
  digitalWrite(green, LOW);
  digitalWrite(amber, HIGH);
  delayAmount();
  digitalWrite(amber, LOW);
  digitalWrite(red, HIGH);
  delayAmount();
  digitalWrite(red, LOW);
}

void pairs() {
  digitalWrite(green, HIGH);
  digitalWrite(amber, HIGH);
  digitalWrite(red, LOW);
  delayAmount();
  digitalWrite(green, LOW);
  digitalWrite(red, HIGH);
  delayAmount();
  digitalWrite(amber, LOW);
  digitalWrite(green, HIGH);
  delayAmount();
  digitalWrite(red, LOW);
}

void loop() {
  sequence();
  pairs();
}
