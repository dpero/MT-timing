# drag-timing
A system for the timing of radio control monster trucks. Could also be used for any form of timed drag racing.

![Image of system](http://nrctpa.org/photo_gallery/2014SpringNationals/album/Racing/slides/Image71.jpg)

## History
I created this software/hardware back in 2002 to fill a need when running our local events. The original software, still in use today, is written in VB6. That IDE has been declared legacy in 2008. I have been wanting to develop a new PC interface in Python for quite some time. I get asked often enough to build a system for folks so I figured I would put up the source so you can build your own.

## Overview

###General
Trucks are staged to the starting line breaking a sensor beam. When start is pressed from the software, a countdown timer begins in the Arduino. Every 0.4 seconds a light is turned on; orange, orange, orange, green. Another timer within the Arduino then starts. When the truck leaves the start line, a timestamp is saved known as the "reaction time". When the truck crosses the finish line, another timestamp is saved known as the "elapsed time". 

### Software
All data is stored in a SQLite database.

Usage flow is as such:
- An event is created
- Drivers are added
- Trucks are created for those drivers
- Trucks/drivers are then registered for an event
- Runs are performed and saved

## Hardware


## Installation

### Arduino
Install the Arduino software and download the latest pde file.
### PC
TBD


## License
GNU General Public License v3.0
