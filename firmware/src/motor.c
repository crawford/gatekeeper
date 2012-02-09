#include "motor.h"
#include "utils.h"
#include <avr/io.h>
#include <util/delay.h>

#define CLOSE_PIN 4
#define OPEN_PIN  5

static inline void MOTOR_DELAY() {
	_delay_ms(100);
}


void init_motor() {
	// THIS IS IMPORTANT!  Pull the two motor pins low
	// (the H-Bridge will short if they are both high)
	WRITE_LOW(&PORTD, OPEN_PIN);
	WRITE_LOW(&PORTD, CLOSE_PIN);

	// Set the two motor pins to output
	SET_MODE(&DDRD, OPEN_PIN, OUTPUT);
	SET_MODE(&DDRD, CLOSE_PIN, OUTPUT);
}

void open() {
	WRITE_HIGH(&PORTD, OPEN_PIN);
	MOTOR_DELAY();
	WRITE_LOW(&PORTD, OPEN_PIN);
}

void close() {
	WRITE_HIGH(&PORTD, CLOSE_PIN);
	MOTOR_DELAY();
	WRITE_LOW(&PORTD, CLOSE_PIN);
}

