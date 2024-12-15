#include <Arduino.h>
#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Wi-Fi credentials
#define WIFI_SSID "DRACARYS"
#define WIFI_PASSWORD "123456789"

// Firebase credentials
#define API_KEY "AIzaSyB8kvEJM9nhzc54Yyf0pvGtsY6wujBo3eU"
#define DATABASE_URL "https://smart-c2aaf-default-rtdb.firebaseio.com/" 

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// DHT11 sensor configuration
#define DHTPIN 12
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Flame sensor configuration
#define FLAME_SENSOR_PIN 4
// Additional configuration to make flame detection more robust
unsigned long lastFlameCheckTime = 0;
const unsigned long FLAME_CHECK_INTERVAL = 1000; // Check flame sensor every 1 second
bool previousFlameState = false;
int flameTriggerCount = 0;
const int FLAME_TRIGGER_THRESHOLD = 3; // Number of consecutive readings to confirm flame

// ACS712 current sensor configuration
#define ACS712_PIN 14
#define SENSOR_CALIBRATION 0.066 // Adjust based on ACS712 model (e.g., 5A, 20A, 30A)

// LED and buzzer configuration
#define LED_PIN 27


// LCD configuration
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Other variables
unsigned long sendDataPrevMillis = 0;
int count = 0;
bool signupOK = false;
bool ledState = false;

// Function to calculate RMS current and energy usage
float calculateEnergyUsage() {
  const int sampleCount = 1000;
  float sum = 0;
  
  for (int i = 0; i < sampleCount; i++) {
 float sensorValue = analogRead(ACS712_PIN) - 512; // Normalize around 0
float current = sensorValue * (5.0 / 1023.0) / SENSOR_CALIBRATION;

    sum += current * current;
    delayMicroseconds(100);
  }
  
 float rmsCurrent = sqrt(sum / sampleCount);

float power = rmsCurrent * 230; // Power in watts
  return power * (millis() / 3600000.0); // Convert to energy usage in kWh
}

// Enhanced flame detection function
bool detectFlame() {
  // Read flame sensor
  bool currentFlameState = (digitalRead(FLAME_SENSOR_PIN) == LOW);
  
  // Implement debounce and trigger logic
  if (currentFlameState == previousFlameState) {
    flameTriggerCount++;
  } else {
    flameTriggerCount = 0;
  }
  
  // Update previous state
  previousFlameState = currentFlameState;
  
  // Return true only if flame is detected consistently
  return (flameTriggerCount >= FLAME_TRIGGER_THRESHOLD) && currentFlameState;
}

// Function to handle Firebase LED control
void handleLEDControl() {
  if (Firebase.RTDB.getBool(&fbdo, "EnergyMonitor/bouton")) {
    bool ledState = fbdo.boolData();
    digitalWrite(LED_PIN, ledState ? HIGH : LOW);
    Serial.print("LED state updated: ");
    Serial.println(ledState ? "ON" : "OFF");
  } else {
    Serial.println("Failed to get LED state");
    Serial.println("REASON: " + fbdo.errorReason());
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected to Wi-Fi");

  // Initialize Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signup successful");
    signupOK = true;
  } else {
    Serial.printf("Firebase signup failed: %s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Initialize sensors and peripherals
  dht.begin();
  pinMode(FLAME_SENSOR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);

  lcd.backlight();
  lcd.clear();
}

void loop() {
  if (Firebase.ready() && signupOK) {
    // Check for LED control changes
    handleLEDControl();

    // Continuously check and send flame sensor data
    if (millis() - lastFlameCheckTime >= FLAME_CHECK_INTERVAL) {
      lastFlameCheckTime = millis();

      // Detect flame with enhanced method
      bool flameDetected = detectFlame();
      
      // Always send flame sensor data to Firebase
      if (Firebase.RTDB.setBool(&fbdo, "EnergyMonitor/flame_detected", flameDetected)) {
        Serial.println("Flame sensor data sent: " + String(flameDetected ? "FLAME DETECTED" : "No Flame"));
      } else {
        Serial.println("Failed to send flame sensor data");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      // Control buzzer based on flame detection
      if (flameDetected) {
       
        Serial.println("ALERT: Flame Detected! Buzzer Activated!");
      } 
    }

    // Send other sensor data every 15 seconds
    if (millis() - sendDataPrevMillis > 15000 || sendDataPrevMillis == 0) {
      sendDataPrevMillis = millis();

      // Read actual sensor values
      float temperature = dht.readTemperature();
      float humidity = dht.readHumidity();
      
      // Calculate energy usage
      float energyUsed = calculateEnergyUsage();

      // Send temperature data to Firebase
      if (Firebase.RTDB.setFloat(&fbdo, "EnergyMonitor/temperature", temperature)) {
        Serial.println("Temperature data sent");
      } else {
        Serial.println("Failed to send temperature data");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      // Send humidity data to Firebase
      if (Firebase.RTDB.setFloat(&fbdo, "EnergyMonitor/humidity", humidity)) {
        Serial.println("Humidity data sent");
      } else {
        Serial.println("Failed to send humidity data");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      // Send energy data to Firebase
     if (Firebase.RTDB.setFloat(&fbdo, "EnergyMonitor/Current", energyUsed)) {
    Serial.println("Energy data sent");
} else {
    Serial.println("Failed to send energy data");
    Serial.println("REASON: " + fbdo.errorReason());
}

      // Send power data to Firebase (assuming 230V AC)
      if (Firebase.RTDB.setFloat(&fbdo, "EnergyMonitor/Power", energyUsed * 230)) {
        Serial.println("Power data sent");
      } else {
        Serial.println("Failed to send power data");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      // Send total energy data to Firebase
      if (Firebase.RTDB.setFloat(&fbdo, "EnergyMonitor/TotalEnergy", energyUsed)) {
        Serial.println("Total energy data sent");
      } else {
        Serial.println("Failed to send total energy data");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      // Update LCD display with actual sensor values
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Temp: ");
      lcd.print(temperature);
      lcd.print("C");
      lcd.setCursor(0, 1);
      lcd.print("Flame: ");
      lcd.print(previousFlameState ? "YES" : "NO");

      // Retrieve LED state from Firebase
      if (Firebase.RTDB.getBool(&fbdo, "EnergyMonitor/bouton")) {
        ledState = fbdo.boolData();
        digitalWrite(LED_PIN, ledState ? HIGH : LOW);
      } else {
        Serial.println("Failed to get LED state");
        Serial.println("REASON: " + fbdo.errorReason());
      }
    }
  }
}