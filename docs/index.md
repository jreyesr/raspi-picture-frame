# WARNING: In progress. Disregard.

# raspi-picture-frame

## Introduction

Recently I decided to try and give some use to an old picture frame that we've had laying around for a very long time.
It's a [Kodak EasyShare D825 picture frame](https://www.amazon.com/Kodak-Easyshare-8-Inch-Digital-Frame/dp/B0030MIUAC)
 which has a sticker on the back that says _Manufactured: December, 2010_. 

// TODO: Picture?

It has a really nice 8-inch 800x600 LCD screen and it was _never_ used.

Naturally, an LCD screen of that size would be an awesome thing to have. Plus, I get to tinker with fast digital signals without using
an oscilloscope!

## The materials

* A Kodak EasyShare D825 picture frame, plus power adapter (5V, 2A)
* A Raspberry Pi 3B+

I could buy a controller board like 
[this one](https://www.ebay.com/itm/VGA-AV-LCD-Controller-Board-For-8inch-A080SN01-V0-800x600-60Pin-LCD-Screen-/274094666413),
but a) it's expensive, especially considering the picture frame was free, b) it doesn't ship here, and c) it takes VGA and composite
video inputs, so I would still need to do acrobatics to display an image from a Raspberry Pi, and composite is ugly.

Therefore, no controller boards allowed. Also, since shipping sucks, no buying connectors online or ordering PCBs.

## Step 1: Observe all the things

The picture frame has the FCC logo and announces FCC compliance on the manual, but I couldn't find it in [fccid.io](https://fccid.io).
Perhaps not all compliant devices need an FCC ID?
Anyways, that means I don't get nice internal photos of the device and other fun documents. Oh well.

There isn't that much inside. A couple of linear regulators for 3.3V and 1.8V, maybe four switching regulators for the LCD voltages
and the LED driver (one of them has a control IC; the other ones do not, and they either get a PWM signal from the main IC or piggyback on other signals),
a RAM chip, some Flash memory and the main IC. It says Amlogic AML6221D, and there are no datasheets for it that I could find.

// TODO Block diagram

The LCD is an A080SN01 V.9 from AU Optronics (datasheet [here](http://www.yslcd.com.tw/docs/product/A080SN01%20V.9.pdf)). It has a 60-pin flex connector
with a 0.5mm pitch, 
and uses a (standard?) RGB interface: you feed it 18-bit RGB (6 red, 6 green, 6 blue) on 18 pins and a 40 MHz clock on another pin, plus either a single 
DEN (data enable) signal or the good old HSYNC and VSYNC signals that are also used on VGA monitors. There are also a bunch of pins for gamma correction, 
an I2C interface that does... something, and multiple voltage rails for the LCD. In this board, HSYNC and VSYNC are left floating, and the microcontroller
drives the RGB signals, DEN and CLK.

I still need the picture frame electronics, because I didn't want to rebuild the gamma correction circuitry (an RC network that generates decreasing voltages)
in a new PCB, nor the four voltage rails with their fun boost converters and proverbial instability issues. Luckily, all the image signal lines are connected
through low value resistors, which means I can desolder the resistors and completely isolate the micro from the image, while still having it drive the
boost converters and getting the auxiliary signals to the LCD panel.

## Step 2: Solder very thin wires and rip up very small pads

Although the PCB designers placed a _lot_ of test pads in the board, they did not place them for the interesting video signals.

That means soldering to one of the only two places where the signals are exposed: either at the flat cable connector or at the resistor pads on the other end.
Soldering at the connector would mean having 20 or so tightly packed wires. I decided to solder to the resistors.

A word of wisdom: AWG24 hookup wire _rips up_ small pads. Don't do it. It causes all-around sadness.
At least I only ripped up one or two pads, but one of them was the MSB of green, which I definitely need.

I ended up using magnet wire (AKA enamelled copper wire, AKA copper wire, but you need to scrape some varnish or something from the ends before it takes solder)
scrounged from a transformer, I think. As such, it comes with no specs, but it's thinner than AWG24 wire. Maybe AWG26 or so? You fix it with hot glue so that an end 
ic close to the pad, maybe a centimeter away, and then solder a _very_ thin wire from the pad to the end of the magnet wire. Leave some slack in the thin wire.
I took the thin wires from a multi-strand AWG22 cable, and they are more or less the same thickness as a hair.

Then comes the soldering. A lot of it. There are 18 color signals, 2 control signals, and a couple of grounds. For each one, you measure, cut and tin
the magnet wire, lay it down and glue it, solder to a piece of perfboard or similar on one side, place the other side near the pad, cut and tin the tiny wire,
solder it to the pad, solder it to the magnet wire, and then cut the excess. Repeat many times, making sure the exposed wires don't touch.
It gets more _interesting_ as time passes, since the last pads are practically covered in wires and you can't get the soldering iron tip in place without desoldering
something else.

// TODO picture of finished soldering?

## Step 3: FPGAs, because why not

After the soldering, you get a nice piece of perfboard with 20 wires neatly soldered side to side.

I then used more magnet wire to bring the signals out to a 20x2 pin header, o fthe kind that mates with a Raspberry Pi GPIO connector. 
See the next section for more information. That gives me a usable connection point, since I can now use Dupont wires to connect there.

The first task is making sure the display works. I used a [TinyFPGA AX2](https://store.tinyfpga.com/products/tinyfpga-a2), 
because I had it around and FPGAs are fun. That just requires three signals: one color, CLK and DEN.

The code that I used is in the repository, in the `/fpga` folder. Of course, now I can't find the page where I found it, 
and it has no names on the header, so I can't give the original source. The `/fpga` folder also includes the `.jed` file that the code generates, 
which can be flashed directly to the TinyFPGA. The `.jed` file uses pins 1, 2 and 3 of the TinyFPGA (the three pins just below the GND pin) for
R, G and B; pin 5 (two pins below 3) for DEN and pin 6 (just below 5) for CLK. Pins 21 and 22 (on the right side, just below VCC) do something, but I didn't care.

The connections end up as follows:

| TinyFPGA       | RPi GPIO header | TFT                   |
| :------------- | :-------------: | --------------------: |
| Pin 1          | Pin 40          | Pin 11 (R7)           |
| Pin 2          | Pin 10          | Pin 19 (G7)           |
| Pin 3          | Pin 21          | Pin 27 (B7)           |
| Pin 5          | Pin 28          | Pin 29 (DE)           |
| Pin 6          | Pin 27          | Pin 28 (DCLK)         |
| Pin 1          | Any GND pin     | The picture frame GND |

Disregard the middle column. It will be useful later. If you wish to replicate this, just ensure that the FPGA pins in the left side connect to the LCD pins 
on the right side.

Also ensure that the grounds are connected. I didn't have to do it, because I powered the FPGA from a USB port in the picture frame, so the ground is shared.

Power on the picture frame. If all goes well, you should see three color bars and a happy face happily bouncing around the screen. That confirms that the LCD
display is working (i.e. not fried)

## Step 4: Raspberry Pi meets VGA monitor

There is a little known feature of the Raspberry Pi. It can output a 24-bit RGB signal on the GPIO header, plus control signals.
Doing so takes all the GPIO header for itself, so no I2C, SPI, serial or pushbuttons, but you still get the WiFi, Bluetooth and USB interfaces.

I heavily used [Robert Ely's article "Let’s add a dirt cheap screen to the Raspberry Pi B+"](http://blog.reasonablycorrect.com/raw-dpi-raspberry-pi/)
for help. I wouldn't have completed this project without that article, with its detailed writeup and spreadsheet for generating some config parameters.

That article, in turn, takes inspiration from [Gert van Loo's vga666](https://github.com/fenlogic/vga666) device, which brings a direct VGA output to
Raspberries. See [here](https://uk.pi-supply.com/products/gert-vga-666-hardware-vga-raspberry-pi) for pictures.

Running a VGA monitor from a Raspberry Pi gives some confidence in the configurations, and from there it's (relatively) easy to use an LCD screen, as it uses
the same hardware.

### Hardware

I made a 1-bit variant of the VGA666 (a 1K resistor and a diode per channel, to clamp the voltage to 0.7V), much like 
[this Arduino version](https://web.archive.org/web/20160331214409/http://garagelab.com/profiles/blogs/arduino-generated-vga-color-signal-complete). 
It can take 3.3V or 5V signals in R, G and B, HSYNC and VSYNC, and translates the R, G and B to the range (0, 0.7) V. It can display 8 colors.
Not much, but it's enough.

Then, the connections are easy.

| RPi GPIO header | VGA monitor                  |
| :-------------  | ---------------------------: |
| Pin 5           | Pin 13 (HSYNC)               |
| Pin 3           | Pin 14 (VSYNC)               |
| Pin 40          | Pin 1 (RED)                  |
| Pin 10          | Pin 2 (GREEN)                |
| Pin 21          | Pin 3 (BLUE)                 |
| Any GND pin     | Pins 5, 6, 7, 8 and 10 (GND) |

### Software

[This](https://www.raspberrypi.org/documentation/hardware/raspberrypi/dpi/README.md) is the official documentation for DPI mode. The simplified instructions
are as follows:

1. Disable SPI and I2C by adding the lines below to `/boot/config.txt`. Alternatively, disable them from `sudo raspi-config`.
```
dtparam=i2c_arm=off
dtparam=spi=off
```
1. Add the following to `/boot/config.txt`
```
dtoverlay=vga666
enable_dpi_lcd=1
display_default_lcd=1
dpi_group=2
dpi_mode=82
```
1. 

## Step 5: Let there be image

## Step 6: Packaging

## Step 7: ?

## Conclusions

## TL;DR

## Useful resources
