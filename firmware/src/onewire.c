/*
   Copyright (c) 2007, Jim Studt

   Removed arduino specific calls, slimmed down codebase, removed all search
   and write functions, and did some formatting -- Alex Crawford, Sept 3, 2011

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

