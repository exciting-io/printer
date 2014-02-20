#include <SPI.h>
#include <Ethernet.h>
#include <SD.h>
#include <EEPROM.h>

#include <SoftwareSerial.h>
#include <Bounce2.h>

// -- Settings for YOU to change if you want

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // physical mac address

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
const char printerType[] = "A2-raw";

const char host[] = "printer.exciting.io"; // the host of the backend server
const unsigned int port = 80;

const unsigned long pollingDelay = 10000; // delay between polling requests (milliseconds)

const byte printer_TX_Pin = 9; // this is the yellow wire
const byte printer_RX_Pin = 8; // this is the green wire
const byte errorLED = 7;       // the red LED
const byte downloadLED = 6;    // the amber LED
const byte readyLED = 5;       // the green LED
const byte buttonPin = 3;      // the print button
const byte SD_Pin = 4;         // the SD Card SPI pin

// #define DEBUG // When debug is enabled, log a bunch of stuff to the hardware Serial

// -- Everything below here can be left alone

const char sketchVersion[] = "1.0.6";

// -- Debugging

#ifdef DEBUG
void debugTimeAndSeparator() {
  Serial.print(millis()); Serial.print(": ");
}
void debug(const char *a) {
  debugTimeAndSeparator(); Serial.println(a);
}
#define debug2(a, b) debugTimeAndSeparator(); Serial.print(a); Serial.println(b);
#else
#define debug(a)
#define debug2(a, b)
#endif


// -- Initialize the printer ID

const byte idAddress = 0;
char printerId[17]; // the unique ID for this printer.

inline void initPrinterID() {
  if ((EEPROM.read(idAddress) == 255) || (EEPROM.read(idAddress+1) == 255)) {
    debug("Generating new ID");
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
  debug2("ID: ", printerId);
}


// -- Initialize the LEDs

inline void initDiagnosticLEDs() {
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
  delay(500);
}

// -- Initialize the printer connection

SoftwareSerial *printer;
#define PRINTER_WRITE(b) printer->write(b)

inline void initPrinter() {
  printer = new SoftwareSerial(printer_RX_Pin, printer_TX_Pin);
  printer->begin(19200);
}


// -- Initialize the SD card

inline void initSD() {
  pinMode(SD_Pin, OUTPUT);
  if (!SD.begin(SD_Pin)) {
    // SD Card failure.
    terminalError(2);
  }
}


// -- Initialize the Ethernet connection & DHCP

EthernetClient client;
inline void initNetwork() {
  // start the Ethernet connection:
  if (Ethernet.begin(mac) == 0) {
    // DHCP Failure
    terminalError(3);
  }
  delay(1000);
  // print your local IP address:
  debug2("IP: ", Ethernet.localIP());
}


// -- Initialize debouncing of buttons

Bounce bouncer = Bounce();

void initBouncer() {
  bouncer.attach(buttonPin);
  bouncer.interval(5);
}

// -- Setup; runs once on boot.

void setup(){
#ifdef DEBUG
  Serial.begin(9600);
#endif
  initDiagnosticLEDs();
  initPrinterID();
  initSD();
  initNetwork();
  initPrinter();
  initBouncer();
}

// -- Check for new data and download if found

boolean downloadWaiting = false;
char cacheFilename[] = "TMP";
unsigned long content_length = 0;
boolean statusOk = false;

void checkForDownload() {
  unsigned long length = 0;
  content_length = 0;
  statusOk = false;

#ifdef DEBUG
  unsigned long start = millis();
#endif

  if (SD.exists(cacheFilename)) {
    if (!SD.remove(cacheFilename)) {
      // Failed to clear cache.
      terminalError(4);
    }
  }
  File cache = SD.open(cacheFilename, FILE_WRITE);

  debug2("Attempting to connect to ", host);
  if (client.connect(host, port)) {
    digitalWrite(downloadLED, HIGH);
    client.print("GET "); client.print("/printer/"); client.print(printerId); client.println(" HTTP/1.0");
    client.print("Host: "); client.print(host); client.print(":"); client.println(port);
    client.flush();
    client.print("Accept: application/vnd.exciting.printer."); client.println(printerType);
    client.print("X-Printer-Version: "); client.println(sketchVersion);
    client.println();
    boolean parsingHeader = true;

    while(client.connected()) {
      while(client.available()) {
        if (parsingHeader) {
          client.find((char*)"HTTP/1.1 ");
          char statusCode[] = "xxx";
          client.readBytes(statusCode, 3);
          statusOk = (strcmp(statusCode, "200") == 0);
          client.find((char*)"Content-Length: ");
          char c;
          while (isdigit(c = client.read())) {
            content_length = content_length*10 + (c - '0');
          }
          debug2("Content length: ", content_length);
          client.find((char*)"\n\r\n"); // the first \r may already have been read above
          parsingHeader = false;
        } else {
          cache.write(client.read());
          length++;
        }
      }
      debug("Waiting for data");
    }

    debug("Server disconnected");
    digitalWrite(downloadLED, LOW);
    // Close the connection, and flush any unwritten bytes to the cache.
    client.stop();
    cache.seek(0);

    if (statusOk) {
      if ((content_length == length) && (content_length == cache.size())) {
        if (content_length > 0) {
          downloadWaiting = true;
          digitalWrite(readyLED, HIGH);
        }
      }
#ifdef DEBUG
      else {
        debug2("Failure, content length: ", content_length);
        if (content_length != length) debug2("length: ", length);
        if (content_length != cache.size()) debug2("cache: ", cache.size());
        digitalWrite(errorLED, HIGH);
      }
#endif
    } else {
      debug("Response code != 200");
      recoverableError();
    }
  } else {
    debug("Couldn't connect");
    recoverableError();
  }

  cache.close();

#ifdef DEBUG
  unsigned long duration = millis() - start;
  debug2("Bytes: ", length);
  debug2("Duration: ", duration);
#endif
}

void flashErrorLEDs(unsigned int times, unsigned int pause) {
  while (times--) {
    digitalWrite(errorLED, HIGH); delay(pause);
    digitalWrite(errorLED, LOW); delay(pause);
  }
}

inline void recoverableError() {
  flashErrorLEDs(5, 100);
}

inline void terminalError(unsigned int times) {
  flashErrorLEDs(times, 500);
  digitalWrite(errorLED, HIGH);
  // no point in carrying on, so do nothing forevermore:
  while(true);
}

// -- Print send any data from the cache to the printer

inline void printFromDownload() {
  File cache = SD.open(cacheFilename);
  byte b;
  while (content_length--) {
    b = (byte)cache.read();
    PRINTER_WRITE(b);
  }
  cache.close();
  downloadWaiting = false;
  digitalWrite(readyLED, LOW);
}


// -- Check for new data, print if the button is pressed.

void loop() {
  if (downloadWaiting) {
    bouncer.update();
    if (bouncer.read() == HIGH) {
      printFromDownload();
    }
  } else {
    checkForDownload();
    if (!downloadWaiting) {
      delay(pollingDelay);
    }
  }
}
