#ifndef UTILS_H
#define UTILS_H

#define F_CPU 1000000
#include <inttypes.h>

static const int INPUT  = 0;
static const int OUTPUT = 1;
static const int HIGH   = 1;
static const int LOW    = 0;

static inline void WRITE(volatile uint8_t *port, int pin, uint8_t status) {
	if (status) {
		*(port) |= (1 << pin);
	} else {
		*(port) &= ~(1 << pin);
	}
}

static inline void WRITE_HIGH(volatile uint8_t *port, int pin) {
	*(port) |= (1 << pin);
}

static inline void WRITE_LOW(volatile uint8_t *port, int pin) {
	*(port) &= ~(1 << pin);
}

static inline uint8_t READ(volatile uint8_t *port, int pin) {
	return *(port) &= 1 << pin;
}

static inline void SET_MODE(volatile uint8_t *port, int pin, uint8_t status) {
	WRITE(port, pin, status);
}

#endif

