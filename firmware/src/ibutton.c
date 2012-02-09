#include <avr/common.h>

#include "ibutton.h"
#include "onewire.h"

uint8_t ibutton[IBUTTON_LEN];
OneWire config;

// Initialize

void init_ibutton() {
	initOneWire(4, &config);
}

// Clear the ibutton from memory and re-enable the interrupts

void ibutton_handled() {
	for (int i = 0; i < IBUTTON_LEN; i++) {
		ibutton[i] = 0;
	}
}


// Handle the one-wire presence pulse by reading the ibutton id and disabling
// the interrupt.

void isr_handle_ibutton_presence() {
	for (int i = 0; i < IBUTTON_LEN; i++) {
		ibutton[i] = read(&config);
	}

	if (ibutton[IBUTTON_LEN - 1] != crc8(ibutton, IBUTTON_LEN - 1, &config)) {
		ibutton_handled();
	}
}

