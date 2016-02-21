/* The Time Machine v0.1
 * 
 * Derrick Pero
 * 07 November 2008
 * 
 * 2010-10-07: for winner condition, turn staged lamp on 
 * 2011-04-20: addition of pro tree option based off input xxx
 * 2012-11-20: Changed Serial.println to be one line of concatenation vs. seperate Serial.print lines 
 * 2012-11-29: Added 'volatile' keyword to severaval variables that are used in the interrupt routines. May have been a problem 
 * 			   with things being overwittin or not updating when needed. See http://arduino.cc/forum/index.php/topic,45239.0.html
 *			   "volatile" ensures that "variable" is reloaded from memory each time it is compared.
 * 2013-10-11: Added blinking LED routine for a indication that the program is running.
 *			   Removed StartPin functionality in favor of a status LED.
 *			   Changed intTreeModePin to 12 in favor of a status LED.
 */

// Inputs
//
// Notes:
//   - The same input is used for start and finish. The software will seperate start from finish.
//   - Inputs are to be sinked to ground.
int inL1SensorsPin = 2; // IRQ0 on digital pin 2 
int inL2SensorsPin = 3; // IRQ1 on digital pin 3
// Start and reset pushbuttons as an alternative to serial start/finish
//int inStartPin = 12; removed on 2013-10-11
// int inResetPin = 13; 2011-04-20
int inTreeModePin = 12; // new 2011-04-20, off = normal, on = pro tree, changed from 13 to 12 on 2013-10-11

// Outputs
//
// Notes:
//  - Outputs are to be logic HIGH or LOW to be compatable with I/O board ????????
int outAmber1Pin = 4;
int outAmber2Pin = 5;
int outAmber3Pin = 6;
int outGreenPin = 7;
int outL1StagedPin = 8;
int outL1RedPin = 9;
int outL2StagedPin = 10;
int outL2RedPin = 11;
int outStatusLedPin = 13;

// Flags
int start = LOW;       // the current state of the start signal from either serial or digital
int started = LOW;     // used to save whether a race was started or not 
volatile int L1Started = LOW;   // flag to indicate if the sensor tripped at the start of a race
volatile int L2Started = LOW;   // flag to indicate if the sensor tripped at the start of a race
volatile int L1Finished = LOW;
volatile int L2Finished = LOW;
volatile int L1DebounceFlag = LOW;
volatile int L2DebounceFlag = LOW;
int TreeMode = LOW;

volatile int L1Sensor = HIGH;    // flag to indicate if the sensor is blocked
volatile int L2Sensor = HIGH;    // flag to indicate if the sensor is blocked
int L1SensorFlag = HIGH;
int L2SensorFlag = HIGH;
int reset = LOW;       // the current state of the reset signal from either serial or digital
int inState;           // the current reading from the input pin

// Time Storage
unsigned long timeGreen;
volatile unsigned long L1StartTime; //"volatile" ensures that "variable" is reloaded from memory each time it is compared.
volatile unsigned long L2StartTime; //"volatile" ensures that "variable" is reloaded from memory each time it is compared.
volatile long L1FinishTime;
volatile long L2FinishTime;
long L1RT;
long L1ET;
long L2RT;
long L2ET;
volatile long L1DebounceTime;
volatile long L2DebounceTime;

//variables to keep track of the blinking status Led
int ledState = LOW;             // ledState used to set the LED
long previousMillis = 0;        // will store last time LED was updated
// the follow variables is a long because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long interval = 1000;           // interval at which to blink (milliseconds)
//

// Serial output string
String strSerialOut;

// from the debounce example
int state = HIGH;      // the current state of the output pin
int previous = LOW;    // the previous reading from the input pin
int incomingByte = 0;	// for incoming serial data
// the follow variables are long's because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long time = 0;         // the last time the output pin was toggled
long debounce = 200;   // the debounce time, increase if the output flickers

//variables to keep track of the timing of recent interrupts
unsigned long button_time = 0;  
unsigned long last_button_time = 0; 

void setup()
{
  pinMode(inL1SensorsPin, INPUT);
  digitalWrite(inL1SensorsPin, HIGH);
  pinMode(inL2SensorsPin, INPUT);
  digitalWrite(inL2SensorsPin, HIGH);
  //pinMode(inStartPin, INPUT);
  // pinMode(inResetPin, INPUT);
  pinMode(inTreeModePin, INPUT);
  
  pinMode(outAmber1Pin, OUTPUT);
  pinMode(outAmber2Pin, OUTPUT);
  pinMode(outAmber3Pin, OUTPUT);
  pinMode(outGreenPin, OUTPUT);
  pinMode(outL1RedPin, OUTPUT);
  pinMode(outL1StagedPin, OUTPUT);
  pinMode(outL2RedPin, OUTPUT);  
  pinMode(outL2StagedPin, OUTPUT);
  pinMode(outStatusLedPin, OUTPUT);       
  
  // Most Arduino boards have two external interrupts: numbers 0 (on digital pin 2) and 1 (on digital pin 3).
  attachInterrupt(0, inL1, CHANGE); // attachInterrupt(interrupt, function, mode)
  attachInterrupt(1, inL2, CHANGE);
   
  Serial.begin(9600);           // set up Serial library at 9600 bps

}

void loop()
{
  
	ReadSerial();            // read serial port
	BlinkLed(); // routine to blink a status led, added 10/11/2013
	//UpdateInputs();   	   // Check inputs, removed 10/11/2013 
	if (reset == HIGH) {
		ResetAll();
		reset = LOW;
	}  
  
	// Start can come from either a serial command or a digital input
	if (start == HIGH && started == LOW) {
		started = HIGH; // so it won't happen again
		//Serial.println("Starting Race");    
		delay(400); // Just a delay so Amber1 doesn't come on immediatly after pressing the start button
		 
		// read input to determine tree mode: off = standard tree, on =  pro tree
		TreeMode = digitalRead(inTreeModePin);
		if (TreeMode == LOW) {   
			// Turn on Amber1
			digitalWrite(outAmber1Pin, HIGH);
			Serial.println("A1(1)");
			delay(400);

			// Turn on Amber2
			digitalWrite(outAmber2Pin, HIGH);
			Serial.println("A2(1)");
			delay(400);

			// Turn on Amber3
			digitalWrite(outAmber3Pin, HIGH);
			Serial.println("A3(1)");
			delay(400);
		}
		if (TreeMode == HIGH) {     
			// Turn on Amber1
			digitalWrite(outAmber1Pin, HIGH);
			// Turn on Amber2
			digitalWrite(outAmber2Pin, HIGH);
			// Turn on Amber3
			digitalWrite(outAmber3Pin, HIGH);
			Serial.println("A1(1)");    
			Serial.println("A2(1)");
			Serial.println("A3(1)");
			delay(400);    
		}

		// Turn on Green
		digitalWrite(outGreenPin, HIGH);
		Serial.println("G(1)");
		timeGreen = millis();      // save start time
		// FOR DEBUG DELETE!!!!!!!!!!!
		//Serial.println(timeGreen);
	}
  
  if (L1Started == HIGH && L1RT == 0) {
  //if (L1RT > 0) {
    L1RT = L1StartTime - timeGreen;
    //send L1 RT
    // Old pre 2012-11-20:
	//Serial.print("L1RT(");
    //Serial.print(L1RT);
    //Serial.println(")");
	// New on 2012-11-20:
	strSerialOut = "L1RT(";
	strSerialOut += L1RT;
	strSerialOut += ")";
    Serial.println(strSerialOut);
	
    if (L1StartTime < timeGreen) { // red lighted
      digitalWrite(outL1RedPin, HIGH);
      Serial.println("L1R(1)");
    }
  }
  if (L2Started == HIGH && L2RT == 0) {
  //if (L1RT > 0) {
    L2RT = L2StartTime - timeGreen;
    //send L2 RT
	strSerialOut = "L2RT(";
	strSerialOut += L2RT;
	strSerialOut += ")";
    Serial.println(strSerialOut);
    if (L2StartTime < timeGreen) { // red lighted
      digitalWrite(outL2RedPin, HIGH);
      Serial.println("L2R(1)");
    }
  }
  
  // Set the debounce flags here. Used to handle the rear tires crossing the start line.  
  if (L1Started == HIGH && L1DebounceFlag == LOW){
    if (millis() > L1DebounceTime){
      L1DebounceFlag = HIGH;
      //Serial.println("L1 debounced!");
    }
  }
  if (L2Started == HIGH && L2DebounceFlag == LOW){
    if (millis() > L2DebounceTime){
      L2DebounceFlag = HIGH;
    }
  }
  
  // send ET here
  if (L1Finished == HIGH && L1ET == 0) {
    L1ET = L1FinishTime - timeGreen;
    //send L1 ET
	strSerialOut = "L1ET(";
	strSerialOut += L1ET;
	strSerialOut += ")";
    Serial.println(strSerialOut);
	// 10-7-2010 for winner condition, turn staged lamp on
	if (L2ET == 0) {
		digitalWrite(outL1StagedPin, HIGH);
	}
  }
  if (L2Finished == HIGH && L2ET == 0) {
    L2ET = L2FinishTime - timeGreen;
    //send L2 ET
	strSerialOut = "L2ET(";
	strSerialOut += L2ET;
	strSerialOut += ")";
    Serial.println(strSerialOut);
	// 10-7-2010 for winner condition, turn staged lamp on
	if (L1ET == 0) {
		digitalWrite(outL2StagedPin, HIGH);
	}	
  }

  // Turn L1 staged lamp on/off
  if (L1Sensor == LOW && L1SensorFlag == LOW) {    // LOW = sink to ground
    digitalWrite(outL1StagedPin, HIGH);    
    Serial.println("L1(1)");  // L1(1): 1 indicates HIGH, needed for GUI
    L1SensorFlag = HIGH;
  }
  if (L1Sensor == HIGH && L1SensorFlag == HIGH) {    // LOW = sink to ground
    digitalWrite(outL1StagedPin, LOW);    
    Serial.println("L1(0)");  // L1(0): 0 indicates LOW, needed for GUI
    L1SensorFlag = LOW; 
  }  

  // Turn L2 staged lamp on/off
  if (L2Sensor == LOW && L2SensorFlag == LOW) {    // LOW = sink to ground
    digitalWrite(outL2StagedPin, HIGH);    
    Serial.println("L2(1)");  // L2(1): 1 indicates HIGH, needed for GUI
    L2SensorFlag = HIGH;
  }
  if (L2Sensor == HIGH && L2SensorFlag == HIGH) {    // LOW = sink to ground
    digitalWrite(outL2StagedPin, LOW);    
    Serial.println("L2(0)");  // L2(0): 0 indicates LOW, needed for GUI
    L2SensorFlag = LOW;
  }  
 
}



// ********************************************************************************
// Handle start (staged) and finish sensors using IRQs.
// Both sensors are wired to the same input pin.
// ********************************************************************************
void inL1 ()
{
// SET A FLAG HERE THAT INPUT IS ON.....


	// Create a variable that are visible to only this function. However unlike local variables 
	//   that get created and destroyed every time a function is called, static variables persist 
	//   beyond the function call, preserving their data between function calls.

	button_time = millis();
	//check to see if increment() was called in the last 250 milliseconds
	if (button_time - last_button_time > 1000)
	{
    
		// Record the state of the pin as the IRQ is set to trigger this routine on CHANGE
		L1Sensor = digitalRead(inL1SensorsPin); 
		//Serial.println(L1Sensor);
		//Serial.println(button_time);
		
			if (start == HIGH) { // Save some time by doing this check first 
				// handle start condition
				if (L1Started == LOW && L1Sensor == HIGH) {
				  L1StartTime = button_time; //millis();
				  L1DebounceTime = L1StartTime + 1000;       // Ignore any inputs for 1000 ms, usually the rear tires
				  L1Started = HIGH;
				}

				// handle finish condition  
				if (L1Started == HIGH && L1Finished == LOW && L1Sensor == LOW && L1DebounceFlag == HIGH) {
				  L1FinishTime = millis();
				  L1Finished = HIGH; 
				}
			}  

		last_button_time = button_time;
	}
	
}  

void inL2 ()
{
  
  L2Sensor = digitalRead(inL2SensorsPin);
  
  if (start == HIGH) { // Save some time by doing this check first 
    // handle start condition
    if (L2Started == LOW && L2Sensor == HIGH) {
      L2StartTime = millis(); 
      L2DebounceTime = L2StartTime + 1000;       // Ignore any inputs for 1000 ms, usually the rear tires
      L2Started = HIGH;
    }

    // handle finish condition  
    if (L2Started == HIGH && L2Finished == LOW && L2Sensor == LOW && L2DebounceFlag == HIGH) {
      L2FinishTime = millis();
      L2Finished = HIGH;
    }
  }  
}  

// ********************************************************************************
// Read and update the digital input state
// ********************************************************************************
void UpdateInputs()
{
  
  inState = digitalRead(inTreeModePin);

  //L1Sensor = digitalRead(inL1SensorsPin);

// From Arduino Playground example:
// Each time the input pin goes from LOW to HIGH (e.g. because of a push-button
// press), the output pin is toggled from LOW to HIGH or HIGH to LOW.  There's
// a minimum delay between toggles to debounce the circuit (i.e. to ignore
// noise).  

  // if we just pressed the button (i.e. the input went from LOW to HIGH),
  // and we've waited long enough since the last press to ignore any noise...  
  if (inState == HIGH && previous == LOW && millis() - time > debounce) {
    // ... invert the output
    if (state == HIGH)
      state = LOW;
    else
      state = HIGH;

    // ... and remember when the last button press was
    time = millis();    
  }

  // digitalWrite(outPin, state);

  previous = inState;
}

// ********************************************************************************
// Read and update the serial port
// ********************************************************************************
void ReadSerial()
{

// send data only when you receive data:
	if (Serial.available() > 0) {
		// read the incoming byte:
		incomingByte = Serial.read();
                if (incomingByte == 82) {      // 82, 'R' for reset
                  reset = HIGH;                 
                }
                else if (incomingByte == 83) {  // 83, 'S' for start
                  start = HIGH;  
                }
		else if (incomingByte == 84) {  // 84, 'T' to resend all times			
				strSerialOut = "L1RT(";
				strSerialOut += L1RT;
				strSerialOut += ")";
				Serial.println(strSerialOut);
				strSerialOut = "L1ET(";
				strSerialOut += L1ET;
				strSerialOut += ")";
				Serial.println(strSerialOut);
				strSerialOut = "L2RT(";
				strSerialOut += L2RT;
				strSerialOut += ")";
				Serial.println(strSerialOut);
				strSerialOut = "L2ET(";
				strSerialOut += L2ET;
				strSerialOut += ")";
				Serial.println(strSerialOut);  
// On the Uno... SRAM = 2k bytes
Serial.println(freeRam());				
                }
              
                // Echo what I got for debug
		// Serial.print("I received: ");
		// Serial.println(incomingByte, DEC);
	}
}

// ********************************************************************************
// Reset all variables and outputs.
// Called from a serial command or the reset PB.
// ********************************************************************************
void ResetAll()
{
  //Serial.println("Resetting Race");    
  
  digitalWrite(outAmber1Pin, LOW);
  digitalWrite(outAmber2Pin, LOW);
  digitalWrite(outAmber3Pin, LOW);
  digitalWrite(outL1RedPin, LOW);  
  digitalWrite(outL2RedPin, LOW);  
  digitalWrite(outGreenPin, LOW);
  // removed 2/19/2012
  //digitalWrite(outL1StagedPin, LOW); // 10-7-2010 for winner condition
  //digitalWrite(outL2StagedPin, LOW); // 10-7-2010 for winner condition
  
  start = LOW;
  started = LOW;
  L1Started = LOW;
  L2Started = LOW;
  L1Finished = LOW;
  L2Finished = LOW;
  L1DebounceFlag = LOW;
  L2DebounceFlag = LOW;
  
  timeGreen = 0;
  L1StartTime = 0;
  L2StartTime = 0;
  L1FinishTime = 0;
  L2FinishTime = 0;
  L1RT = 0;
  L2RT = 0;
  L1ET = 0;
  L2ET = 0; 
  L1DebounceTime = 0;
  L2DebounceTime = 0;
  
  Serial.println("A1(0)");
  Serial.println("A2(0)");
  Serial.println("A3(0)");
  Serial.println("G(0)");
  Serial.println("L1R(0)");
  Serial.println("L2R(0)");
  
  strSerialOut = "L1RT(";
  strSerialOut += L1RT;
  strSerialOut += ")";
  Serial.println(strSerialOut);
  strSerialOut = "L1ET(";
  strSerialOut += L1ET;
  strSerialOut += ")";
  Serial.println(strSerialOut);
  strSerialOut = "L2RT(";
  strSerialOut += L2RT;
  strSerialOut += ")";
  Serial.println(strSerialOut);
  strSerialOut = "L2ET(";
  strSerialOut += L2ET;
  strSerialOut += ")";
  Serial.println(strSerialOut);              

}

int freeRam () 
{
  extern int __heap_start, *__brkval; 
  int v; 
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}

void BlinkLed ()
{
// check to see if it's time to blink the LED; that is, if the 
  // difference between the current time and last time you blinked 
  // the LED is bigger than the interval at which you want to 
  // blink the LED.
  unsigned long currentMillis = millis();
 
  if(currentMillis - previousMillis > interval) {
    // save the last time you blinked the LED 
    previousMillis = currentMillis;   

    // if the LED is off turn it on and vice-versa:
    if (ledState == LOW)
      ledState = HIGH;
    else
      ledState = LOW;

    // set the LED with the ledState of the variable:
    digitalWrite(outStatusLedPin, ledState);
  }
}
