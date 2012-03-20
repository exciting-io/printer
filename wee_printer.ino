#include <SPI.h>
#include <Ethernet.h>
#include <SD.h>

#include <SoftwareSerial.h>
#include <Thermal.h>
#include <Bounce.h>

#define DEBUG
#ifdef DEBUG
#define debug(a) Serial.print(millis()); Serial.print(": "); Serial.println(a);
#define debug2(a, b) Serial.print(millis()); Serial.print(": "); Serial.print(a); Serial.println(b);
#else
#define debug(a)
#define debug2(a, b)
#endif

const int errorLED = 5;
const int downloadLED = 6;
const int readyLED = 7;

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

const int printer_RX_Pin = 2;  // this is the green wire
const int printer_TX_Pin = 3;  // this is the yellow wire
Thermal printer(printer_RX_Pin, printer_TX_Pin);
const int postPrintFeed = 3;

void initPrinter() {
  printer.begin(150);
}

const int SD_Pin = 4;
void initSD() {
  pinMode(SD_Pin, OUTPUT);
  SD.begin(SD_Pin);
}

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x86, 0x67 }; //physical mac address
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
  Serial.begin(9600);

  initSD();
  initNetwork();
  initPrinter();
  initDiagnosticLEDs();
}

//const char* host = "192.168.1.22"; // uberatom
//const char* host = "192.168.1.67"; // lazyatom
//const char* host = "178.79.132.137"; // interblah
const char* host = "wee-printer.interblah.net";
const uint16_t port = 80;
const char *path = "/printer/1";

uint16_t failures = 0;
uint16_t requests = 0;
boolean downloadWaiting = false;
char* cacheFilename = "TMP";

void checkForDownload() {
  uint32_t length = 0;
  uint32_t content_length = 0;

  if (SD.exists(cacheFilename)) SD.remove(cacheFilename);
  File cache = SD.open(cacheFilename, FILE_WRITE);

  if (client.connect(host, port)) {
    digitalWrite(downloadLED, HIGH);
    client.print("GET "); client.print(path); client.println(" HTTP/1.0\n"); 
    boolean parsingHeader = true;
    unsigned long start = millis();
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
    cache.close();

    unsigned long duration = millis() - start;
    debug2("Total bytes: ", length);
    debug2("Duration: ", duration);
    debug2("Speed: ", length/(duration/1000.0)); // NB - floating point math increases sketch size by ~2k

    if (success) {
      if (content_length > 0) {
        downloadWaiting = true;
        digitalWrite(readyLED, HIGH);
      }
    } else {
      failures++;
      debug2("Oh no, a failure: ", failures);
      digitalWrite(errorLED, HIGH);
      digitalWrite(downloadLED, HIGH);
    }
  } else {
    debug("Couldn't connect");
    digitalWrite(errorLED, HIGH);
  }
}

void printFromDownload() {
  File cache = SD.open(cacheFilename);
  printer.printBitmap(&cache);
  printer.feed(postPrintFeed);
  cache.close();
}

const int buttonPin = 8;
Bounce bouncer = Bounce(buttonPin, 5); // 5 millisecond debounce
unsigned long pollingDelay = 10000; // 1 minute

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