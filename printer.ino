#include <SPI.h>
#include <Ethernet.h>
#include <SD.h>
#include <EEPROM.h>

#include <SoftwareSerial.h>
#include <Bounce.h>

// ------- Settings for YOU to change if you want ---------------------

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x86, 0x67 }; // physical mac address

// The printerType controls the format of the data sent from the server
// If you're using a completely different kind of printer, change this
// to correspond to your printer's PrintProcessor implementation in the
// server.
//
// If you want to control the darkness of your printouts, append a dot and
// a number, e.g. A2-raw.240 (up to a maximum of 255).
//
// If you want to flip the vertical orientation of your printouts, append
// a number and then .flipped, e.g. A2-raw.240.flipped
const char *printerType = "A2-raw";

const char* host = "printer.gofreerange.com"; // the host of the backend server
const unsigned int port = 80;

const unsigned long pollingDelay = 10000; // delay between polling requests (milliseconds)

const byte printer_TX_Pin = 9; // this is the yellow wire
const byte printer_RX_Pin = 8; // this is the green wire
const byte errorLED = 7;       // the red LED
const byte downloadLED = 6;    // the amber LED
const byte readyLED = 5;       // the green LED
const byte buttonPin = 3;      // the print button

// --------------------------------------------------------------------

// #define DEBUG
#ifdef DEBUG
#define debug(a) Serial.print(millis()); Serial.print(": "); Serial.println(a);
#define debug2(a, b) Serial.print(millis()); Serial.print(": "); Serial.print(a); Serial.println(b);
#else
#define debug(a)
#define debug2(a, b)
#endif

const byte idAddress = 0;
char printerId[17]; // the unique ID for this printer.

void initSettings() {
  if ((EEPROM.read(idAddress) == 255) || (EEPROM.read(idAddress+1) == 255)) {
    debug("Generating new printer ID.");
    randomSeed(analogRead(0) * analogRead(5));
    for(int i = 0; i < 16; i += 2) {
      printerId[i] = random(48, 57); // 0-9
      printerId[i+1] = random(97, 122); // a-z
      EEPROM.write(idAddress + i, printerId[i]);
      EEPROM.write(idAddress + i+1, printerId[i+1]);
    }
  } else {
    for(int i = 0; i < 16; i++) {
      printerId[i] = (char)EEPROM.read(idAddress + i);
    }
  }
  printerId[16] = '\0';
  debug2("Printer ID: ", printerId);
}

void initDiagnosticLEDs() {
  pinMode(errorLED, OUTPUT);
  pinMode(downloadLED, OUTPUT);
  pinMode(readyLED, OUTPUT);
  digitalWrite(errorLED, HIGH);
  digitalWrite(downloadLED, HIGH);
  digitalWrite(readyLED, HIGH);
  delay(1000);
  digitalWrite(errorLED, LOW);
  digitalWrite(downloadLED, LOW);
  digitalWrite(readyLED, LOW);
}

SoftwareSerial *printer;
#define PRINTER_WRITE(b) printer->write(b)

void initPrinter() {
  printer = new SoftwareSerial(printer_RX_Pin, printer_TX_Pin);
  printer->begin(19200);
}

const byte SD_Pin = 4;
void initSD() {
  pinMode(SD_Pin, OUTPUT);
  SD.begin(SD_Pin);
}

EthernetClient client;
void initNetwork() {
  // start the Ethernet connection:
  if (Ethernet.begin(mac) == 0) {
    debug("DHCP Failed");
    // no point in carrying on, so do nothing forevermore:
    while(true);
  }
  delay(1000);
  // print your local IP address:
  debug2("IP address: ", Ethernet.localIP());
}

void setup(){
#ifdef DEBUG
  Serial.begin(9600);
#endif

  initSettings();
  initSD();
  initNetwork();
  initPrinter();
  initDiagnosticLEDs();
}

boolean downloadWaiting = false;
char* cacheFilename = "TMP";
unsigned long content_length = 0;

void checkForDownload() {
  unsigned long length = 0;
  content_length = 0;
  if (SD.exists(cacheFilename)) {
    if (SD.remove(cacheFilename)) {
      debug("Cleared cache");
    } else {
      debug("Failed to clear cache for some reason");
    }
  }
  File cache = SD.open(cacheFilename, FILE_WRITE);
  debug2("starting request, cache size is ", cache.size());

  debug2("Attempting to connect to ", host);
  if (client.connect(host, port)) {
    digitalWrite(downloadLED, HIGH);
    client.print("GET "); client.print("/printer/"); client.print(printerId); client.println(" HTTP/1.0");
    client.print("Host: "); client.print(host); client.print(":"); client.println(port);
    client.print("Accept: application/vnd.freerange.printer."); client.println(printerType);
    client.println();
    boolean parsingHeader = true;
#ifdef DEBUG
    unsigned long start = millis();
#endif
    while(client.connected()) {
      debug("Still connected");
      while(client.available()) {
        if (parsingHeader) {
          client.find("Content-Length: ");
          char c;
          while (isdigit(c = client.read())) {
            content_length = content_length*10 + (c - '0');
          }
          debug2("Content length was: ", content_length);
          client.find("\n\r\n"); // the first \r may already have been read above
          parsingHeader = false;
        } else {
          cache.write(client.read());
          length++;
        }
      }
      debug("No more data to read at the moment...");
    }

    debug("Server has disconnected");
    digitalWrite(downloadLED, LOW);
    // Close the connection, and flush any unwritten bytes to the cache.
    client.stop();
    cache.seek(0);
    boolean success = (content_length == length) && (content_length == cache.size());
#ifdef DEBUG
    if (!success) {
      debug2("Failure, content length was ", content_length);
      if (content_length != length) {
        debug2("but length was ", length);
      }
      if (content_length != cache.size()) {
        debug2("but cache size was ", cache.size());
      }
    }
#endif
    cache.close();

#ifdef DEBUG
    unsigned long duration = millis() - start;
    debug2("Total bytes: ", length);
    debug2("Duration: ", duration);
    debug2("Speed: ", length/(duration/1000.0)); // NB - floating point math increases sketch size by ~2k
#endif

    if (success) {
      if (content_length > 0) {
        downloadWaiting = true;
        digitalWrite(readyLED, HIGH);
      }
    } else {
      debug("Oh no, a failure.");
      digitalWrite(errorLED, HIGH);
      digitalWrite(downloadLED, HIGH);
    }
  } else {
    debug("Couldn't connect");
    cache.close();
    byte i = 5;
    while(i--) {
      digitalWrite(errorLED, HIGH);
      delay(100);
      digitalWrite(errorLED, LOW);
      delay(100);
    }
  }
}

void printFromDownload() {
  File cache = SD.open(cacheFilename);
  byte b;
  while (content_length--) {
    b = (byte)cache.read();
    PRINTER_WRITE(b);
  }
  cache.close();
}

Bounce bouncer = Bounce(buttonPin, 5); // 5 millisecond debounce

void loop() {
  if (downloadWaiting) {
    bouncer.update();
    if (bouncer.read() == HIGH) {
      printFromDownload();
      downloadWaiting = false;
      digitalWrite(readyLED, LOW);
    }
  } else {
    delay(pollingDelay);
    checkForDownload();
  }
}
