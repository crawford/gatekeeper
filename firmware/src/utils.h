#ifndef UTILS_H
#define UTILS_H

#define F_CPU 1000000
#include <inttypes.h>

#define INPUT  0
#define OUTPUT 1
#define HIGH   1
#define LOW    0

static inline void WRITE(volatile uint8_t *port, int pin, uint8_t status) {
	if (status) {
		WRITE_HIGH(port, pin);
	} else {
		WRITE_LOW(port, pin);
	}
}

static inline void WRITE_HIGH(volatile uint8_t *port, int pin) {
	*(port) |= (1 << pin);
}

static inline void WRITE_LOW(volatile uint8_t *port, int pin) {
	*(port) &= ~(1 << pin);
}

static inline uint8_t READ(volatile uint8_t *port, int pin) {
	return *(port) & 1 << pin;
}

static inline void SET_MODE(volatile uint8_t *port, int pin, uint8_t status) {
	WRITE(port, pin, status);
}

#endif

