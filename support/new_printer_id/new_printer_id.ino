/*

  This sketch can be used to generate a new ID for a printer.

  If will replace the existing ID.

*/


#include <EEPROM.h>

const byte idAddress = 0;
char printerId[17]; // the unique ID for this printer.

void setup() {
  Serial.begin(9600);
  randomSeed(analogRead(0) * analogRead(5));
  for(int i = 0; i < 16; i += 2) {
    printerId[i] = random(48, 57);
    printerId[i+1] = random(97, 122);
    EEPROM.write(idAddress + i, printerId[i]);
    EEPROM.write(idAddress + i+1, printerId[i+1]);
  }
  printerId[16] = '\0';
  Serial.print("Printer ID: "); Serial.println(printerId);
}

void loop() {
}
