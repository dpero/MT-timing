# MT-timing
A system for the timing and event handling for radio control monster trucks. Could also be used for any form of timed drag racing.

![Image of system](http://nrctpa.org/photo_gallery/2014SpringNationals/album/Racing/slides/Image71.jpg)

## History
I created this software/hardware back in 2002 to fill a need when running our local events. The original software, still in use today, is written in VB6. That IDE has been declared legacy in 2008. I have been wanting to develop a new PC interface in Python for quite some time. I get asked often enough to build a system for folks so I figured I would put up the source so you can build your own.

## Overview

###General
Trucks are staged to the starting line breaking a sensor beam. When start is pressed from the software, a countdown timer begins in the Arduino. Every 0.4 seconds a light is turned on; orange, orange, orange, green. Another timer within the Arduino then starts. When the truck leaves the start line, a timestamp is saved known as the "reaction time". When the truck crosses the finish line, another timestamp is saved known as the "elapsed time". 

### Software
I am not going to upload the VB6 code as very few would be able to make use of it. Instead, I will use this space to be the home of a new Python/QT UI.

Usage flow is as such:
- An event is created
- Drivers are added
- Trucks are created for those drivers
- Trucks/drivers are then registered for an event
- Runs are performed and saved

All data to be stored in a SQLite database.

## Hardware

### Arduino
I chose the Arduino platform for performing timing duties. The code has been proven to work on a Diecimila and UNO. Other boards will probably work so long as they have the required inputs and outputs. It can be powered by USB but I like to use an external 5V supply.

####Inputs
The same input is used for start and finish. The code will seperate start from finish. The inputs are tied to IRQs for speedy handling.
```
int inL1SensorsPin = 2; // IRQ0 on digital pin 2 
int inL2SensorsPin = 3; // IRQ1 on digital pin 3
int inTreeModePin = 12; // off = normal, on = pro tree
```
Arduino inputs are 5V and some method is needed to convert sensor voltage down to 5Vdc. Optically isolated is the way to go. I have used an [Opto22 IDC5](http://www.opto22.com/site/pr_details.aspx?cid=4&item=IDC5) DC input module.

####Outputs
Some method of lighting is needed. Industrial stack lights work well for this. I have used Telemecanique brand but most any of them would work. Try to use LED lamps to keep current requirements down.
```
int outAmber1Pin = 4;
int outAmber2Pin = 5;
int outAmber3Pin = 6;
int outGreenPin = 7;
int outL1StagedPin = 8;
int outL1RedPin = 9;
int outL2StagedPin = 10;
int outL2RedPin = 11;
```
Arduino outputs are 5Vdc and can only handle 40 mA. Some method of changing to a higher current, and most likely voltage, is necessary. My current system uses a custom I/O board that gets the job done but is a little expensive and time consuming to fabricate. There are other options:
- An Opto22 Output module and rack like the [PB16A](http://www.opto22.com/site/pr_details.aspx?cid=4&item=PB16A)
- some sort of Arduino relay shield or module
- Perhaps this [IRF520 MOS Driver Module](http://www.gearbest.com/sensors/pp_226185.html) @ $1.47 ea

I like the solid state options reather than mechanical relays. 

### Sensors
Start and finish line sensors are needed. For the start I have been using Banner Engineering SM312LV retroreflective photoelectric sensors. For the finish I used Banner Engineering SM31E & SM31R infrared opposed beam sensors. They are relatively inexpensive (when sourced on eBay), very fast, and operate at a wide voltage range (10-30 Vdc).
### Power supply
You will need a power supply. Choose one that will power your sensors and lights.
### Enclosure
You will need some sort of enclosure to put all this stuff in. My first system used an old PC tower. My current system is in a MDF box. If I were to build another, I would go smaller. The stack lights would be next to each starting line with the cables going back to a central box housing the Arduino and power supply.
### BetaBrite sign
Not required but a nice touch. I sourced mine off eBay. It is controled from software on the PC via a USB port and a USB->RS232 converter.

## Installation

### Arduino
Install the Arduino software and download the latest pde file.
### PC
Not yet...


## License
GNU General Public License v3.0
