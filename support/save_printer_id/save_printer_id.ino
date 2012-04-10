/*

  This sketch can be used to explicitly set the ID of a printer.

  You should chose a random, 16 character string of digits and numbers
  (no punctuation or any other characters invalid in a URL).

*/

#include <EEPROM.h>

const byte idAddress = 0;
char printerId[] =  "16char_printerid"; // Set this to a random 16 character string!

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < 16; i++ ) {
    EEPROM.write(idAddress + i, printerId[i]);
  }
  Serial.print("Saved printer ID: "); Serial.println(printerId);
}

void loop() {
}
