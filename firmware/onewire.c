/*
   Copyright (c) 2007, Jim Studt

   Removed arduino specific calls, slimmed down codebase, and did some
   formatting -- Alex Crawford, Sept 3, 2011

   Updated to work with arduino-0008 and to include skip(OneWire* data) as of
   2007/07/06. --RJL20

   Modified to calculate the 8-bit CRC directly, avoiding the need for
   the 256-byte lookup table to be loaded in RAM.  Tested in arduino-0010
   -- Tom Pollard, Jan 23, 2008

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial data->portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   Much of the code was inspired by Derek Yerger's code, though I don't
   think much of that remains.  In any event that was..
   (copyleft) 2006 by Derek Yerger - Free to distribute freely.

   The CRC code was excerpted and inspired by the Dallas Semiconductor
   sample code bearing this copyright.
//---------------------------------------------------------------------------
// Copyright (C) 2000 Dallas Semiconductor Corporation, All Rights Reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial data->portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL DALLAS SEMICONDUCTOR BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// Except as contained in this notice, the name of Dallas Semiconductor
// shall not be used except as stated in the Dallas Semiconductor
// Branding Policy.
//--------------------------------------------------------------------------
 */

#include "onewire.h"
#include "utils.h"
#include <avr/io.h>
#include <util/delay.h>

void initOneWire(uint8_t pinArg, OneWire* data) {
	data->pin       = pinArg;
	data->port      = 0;
	data->bitmask   = 1 << data->pin;
	data->outputReg = &PORTB;
	data->inputReg  = &PINB;
	data->modeReg   = &DDRB;
}

//
// Perform the onewire reset function.  We will wait up to 250uS for
// the bus to come high, if it doesn't then it is broken or shorted
// and we return a 0;
//
// Returns 1 if a device asserted a presence pulse, 0 otherwise.
//
uint8_t reset(OneWire* data) {
	uint8_t r;
	uint8_t retries;
	retries= 125;

	// wait until the wire is high... just in case
	SET_MODE(data->modeReg, data->pin, INPUT);
	do {
		if (retries-- == 0)
			return 0;

		_delay_ms(2);
	} while (!READ(data->inputReg, data->pin));

	SET_MODE(data->modeReg, data->pin, OUTPUT);
	WRITE_LOW(data->outputReg, data->pin);         // pull low for 500uS
	_delay_ms(500);
	SET_MODE(data->modeReg, data->pin, INPUT);
	WRITE_HIGH(data->outputReg, data->pin);        //enable pullup

	_delay_ms(65);
	r = READ(data->inputReg, data->pin);
	_delay_ms(490);

	return r;
}

//
// Write a bit. data->port and bit is used to cut lookup time and provide
// more certain timing.
//
void write_bit(uint8_t v, OneWire* data) {
	static uint8_t lowTime[]  = { 55, 5 };
	static uint8_t highTime[] = { 5, 55 };

	v = (v & 1);
	*(data->modeReg) |= data->bitmask;    // make data->pin an output, do first
	                                      // since we expect to be at 1
	*(data->outputReg) &= ~data->bitmask; // zero
	_delay_ms(lowTime[v]);
	*(data->outputReg) |= data->bitmask;  // one, push data->pin up - important for
	                                      // parasites, they might start in here
	_delay_ms(highTime[v]);
}

//
// Read a bit. data->port and bit is used to cut lookup time and provide
// more certain timing.
//
uint8_t read_bit(OneWire* data) {
	uint8_t r;

	*(data->modeReg) |= data->bitmask;    // make data->pin an output, do first
	                                      // since we expect to be at 1
	*(data->outputReg) &= ~data->bitmask; // zero
	_delay_ms(1);
	*(data->modeReg) &= ~data->bitmask;   // let data->pin float, pull up will raise
	_delay_ms(1);                         // A "read slot" is when 1mcs > t > 2mcs

	                                      // check the bit
	r = (*(data->inputReg) & data->bitmask) ? 1 : 0;
	_delay_ms(50);                        // whole bit slot is 60-120uS,

	                                      // need to give some time
	return r;
}

//
// Write a byte. The writing code uses the active drivers to raise the
// data->pin high, if you need power after the write (e.g. DS18S20 in
// parasite power mode) then set 'power' to 1, otherwise the data->pin will
// go tri-state at the end of the write to avoid heating in a short or
// other mishap.
//
void write(uint8_t v, uint8_t power, OneWire* data) {
	uint8_t bitmask;

	for (bitmask = 0x01; bitmask; bitmask <<= 1) {
		write_bit( (bitmask & v) ? 1 : 0, data);
	}
	if (!power) {
		SET_MODE(data->modeReg, data->pin, INPUT);
		WRITE_HIGH(data->outputReg, data->pin);
	}
}

//
// Read a byte
//
uint8_t read(OneWire* data) {
	uint8_t bitmask;
	uint8_t r = 0;

	for (bitmask = 0x01; bitmask; bitmask <<= 1) {
		if (read_bit(data))
			r |= bitmask;
	}

	return r;
}

//
// Do a ROM select
//
void select(uint8_t rom[8], OneWire* data) {
	int i;

	write(0x55 , 0, data);         // Choose ROM

	for (i = 0; i < 8; i++) {
		write(rom[i], 0, data);
	}
}

//
// Do a ROM skip
//
void skip(OneWire* data) {
	write(0xCC, 0, data);         // Skip ROM
}

void depower(OneWire* data) {
	SET_MODE(data->modeReg, data->pin, INPUT);
}

//
// Compute a Dallas Semiconductor 8 bit CRC directly.
//
uint8_t crc8(uint8_t *addr, uint8_t len, OneWire* data) {
	uint8_t i, j;
	uint8_t crc = 0;

	for (i = 0; i < len; i++) {
		uint8_t inbyte = addr[i];
		for (j = 0; j < 8; j++) {
			uint8_t mix = (crc ^ inbyte) & 0x01;
			crc >>= 1;
			if (mix)
				crc ^= 0x8C;

			inbyte >>= 1;
		}
	}

	return crc;
}

