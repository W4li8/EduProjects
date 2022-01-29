/*
 *    LedControl.h - A library for controling Leds with a MAX7219/MAX7221
 *    Copyright (c) 2007 Eberhard Fahle
 *
 *    Permission is hereby granted, free of charge, to any person
 *    obtaining a copy of this software and associated documentation
 *    files (the "Software"), to deal in the Software without
 *    restriction, including without limitation the rights to use,
 *    copy, modify, merge, publish, distribute, sublicense, and/or sell
 *    copies of the Software, and to permit persons to whom the
 *    Software is furnished to do so, subject to the following
 *    conditions:
 *
 *    This permission notice shall be included in all copies or
 *    substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *    OTHER DEALINGS IN THE SOFTWARE.
 *
 *    Modified to our application on the DE1-SoC to interface with 8x8 led matrix.
 */

#include <io.h>
#include <system.h>

#ifndef LedControl_h
#define LedControl_h

#define byte 	unsigned char
#define uint8_t unsigned char

/* SPI SETTINGS */
#define LOW  		0
#define HIGH 		1

#define LSBFIRST	0
#define MSBFIRST	1

/* PARALLEL PORT REGISTERS (size: 8) */
#define IREGDIR 		0
#define IREGPIN 		1
#define IREGPORT 		2
#define IREGPORTSET 	3
#define IREGPORTCLR 	4

#define MODE_ALL_OUTPUT	0xFF
#define MODE_ALL_INPUT	0x00

/* PHYSICAL SETUP */
#define GPIO_0	PARALLEL_PORT_0_BASE
#define DIN 	2
#define CS  	1
#define CLK 	0


/* NOT the arduino digitalWrite -- Custom made for the led matrix on our FPGA and parallel port */
void digitalWrite(int pin, int val);


class LedControl {
    private :
        /* The array for shifting the data to the devices */
        byte spidata[16];
        /* Send out a single command to the device */
        void spiTransfer(int addr, byte opcode, byte data);
        /* Implementation copied from the following link, official arduino version
         * https://stackoverflow.com/questions/62953355/how-to-implement-arduino-uno-shiftout-in-avr-c */
        void shiftOut(uint8_t dataPin, uint8_t clockPin, uint8_t bitOrder, uint8_t val);

        /* We keep track of the led status for all 8 devices in this array */
        byte status[64];
        /* Data is shifted out of this pin*/
        int SPI_MOSI;
        /* The clock is signaled on this pin */
        int SPI_CLK;
        /* This one is driven LOW for chip selection */
        int SPI_CS;
        /* The maximum number of devices we use */
        int maxDevices;

    public:
        /*
         * Create a new controller
         * Params :
         * dataPin	  pin on the Arduino where data gets shifted out
         * clockPin	  pin for the clock
         * csPin	  pin for selecting the device
         * numDevices maximum number of devices that can be controlled
         */
        LedControl(int dataPin, int clkPin, int csPin, int numDevices=1);

        /*
         * Set the shutdown (power saving) mode for the device
         * Params :
         * addr	The address of the display to control
         * status if true the device goes into power-down mode, set to false for normal operation
         */
        void shutdown(int addr, bool status);

        /*
         * Set the number of digits (or rows) to be displayed.
         * See datasheet for sideeffects of the scanlimit on the brightness
         * of the display.
         * Params :
         * addr	address of the display to control
         * limit	number of digits to be displayed (1..8)
         */
        void setScanLimit(int addr, int limit);

        /*
         * Set the brightness of the display.
         * Params:
         * addr		 the address of the display to control
         * intensity the brightness of the display (0..15)
         */
        void setIntensity(int addr, int intensity);

        /*
         * Switch all leds on the display off.
         * Params:
         * addr	address of the display to control
         */
        void clearDisplay(int addr);

        /*
         * Set the status of a single led.
         * Params :
         * addr	 address of the display
         * row	 the row of the led (0..7)
         * col	 the column of the led (0..7)
         * state if true the led is switched on, if false it is switched off
         */
        void setLed(int addr, int row, int col, bool state);

        /*
         * Set all 8 leds in a column to a new state
         * Params:
         * addr	 address of the display
         * col	 column which is to be set (0..7)
         * value each bit set to 1 will light up the corresponding led
         */
        void setColumn(int addr, int col, byte value);

        /*
         * Set all 8 leds in a row to a new state
         * Params:
         * addr	 address of the display
         * row	 row which is to be set (0..7)
         * value each bit set to 1 will light up the corresponding led.
         */
        void setRow(int addr, int row, byte value);
};

#endif	//LedControl.h



