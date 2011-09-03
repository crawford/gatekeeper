#define F_CPU 1000000

#include "motor.h"
#include <avr/io.h>
#include <util/delay.h>

static const int CLOSE_PIN = 4;
static const int OPEN_PIN  = 5;

static inline void OUTPUT_HIGH(pin) {
	PORTD |= (1 << pin);
}

static inline void OUTPUT_LOW(pin) {
	PORTD &= ~(1 << pin);
}

static inline void MOTOR_DELAY() {
	_delay_ms(100);
}


void init_motor() {
	// THIS IS IMPORTANT!  Pull the two motor pins low
	// (the H-Bridge will short if they are both high)
	OUTPUT_LOW(OPEN_PIN);
	OUTPUT_LOW(CLOSE_PIN);

	// Set the two motor pins to output
	DDRD |= (1 << OPEN_PIN);
	DDRD |= (1 << CLOSE_PIN);
}

void open() {
	OUTPUT_HIGH(OPEN_PIN);
	MOTOR_DELAY();
	OUTPUT_LOW(OPEN_PIN);
}

void close() {
	OUTPUT_HIGH(CLOSE_PIN);
	MOTOR_DELAY();
	OUTPUT_LOW(CLOSE_PIN);
}

