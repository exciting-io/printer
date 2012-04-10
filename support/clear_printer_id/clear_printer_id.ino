/*

  This sketch can be used to remove a printer ID.

  It should then be re-generated on first boot.

*/

#include <EEPROM.h>

const byte idAddress = 0;

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < 16; i++ ) {
    EEPROM.write(idAddress + i, 0xFF);
  }
  Serial.println("Cleared printer ID.");
}

void loop() {
}
