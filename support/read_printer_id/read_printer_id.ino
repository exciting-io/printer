/*

  This sketch can be used to determine the ID of a printer.

*/


#include <EEPROM.h>

const byte idAddress = 0;
char printerId[17]; // the unique ID for this printer.

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < 16; i++) {
    printerId[i] = (char)EEPROM.read(idAddress + i);
  }
  printerId[16] = '\0';
  Serial.print("Printer ID: "); Serial.println(printerId);
}

void loop() {
}
