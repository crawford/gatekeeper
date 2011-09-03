#ifndef ONEWIRE_H
#define ONEWIRE_H

#include <inttypes.h>

typedef struct {
	uint8_t pin;
	uint8_t port;
	uint8_t bitmask;
	volatile uint8_t *outputReg;
	volatile uint8_t *inputReg;
	volatile uint8_t *modeReg;
} OneWire;

void initOneWire(uint8_t pin, OneWire* data);

// Perform a 1-Wire reset cycle. Returns 1 if a device responds
// with a presence pulse.  Returns 0 if there is no device or the
// bus is shorted or otherwise held low for more than 250uS
uint8_t reset(OneWire* data);

// Issue a 1-Wire rom select command, you do the reset first.
void select(uint8_t rom[8], OneWire* data);

// Issue a 1-Wire rom skip command, to address all on bus.
void skip(OneWire* data);

// Write a byte. If 'power' is one then the wire is held high at
// the end for parasitically powered devices. You are responsible
// for eventually depowering it by calling depower(OneWire* data) or doing
// another read or write.
void write(uint8_t v, uint8_t power, OneWire* data);

// Read a byte.
uint8_t read(OneWire* data);

// Write a bit. The bus is always left powered at the end, see
// note in write(OneWire* data) about that.
void write_bit(uint8_t v, OneWire* data);

// Read a bit.
uint8_t read_bit(OneWire* data);

// Stop forcing power onto the bus. You only need to do this if
// you used the 'power' flag to write(OneWire* data) or used a
// write_bit(OneWire* data) call and aren't about to do another
// read or write. You would rather not leave this powered if you
// don't have to, just in case someone shorts your bus.
void depower(OneWire* data);

// Compute a Dallas Semiconductor 8 bit CRC, these are used in the
// ROM and scratchpad registers.
uint8_t crc8(uint8_t *addr, uint8_t len, OneWire* data);

#endif

