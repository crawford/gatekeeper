#include <avr/io.h>
#include "leds.h"
#include "motor.h"
#include "ibutton.h"

void sleep();

int main() {
	init_leds();
	init_motor();
	init_ibutton();
	//init_xbee();

	uint8_t has_ibutton;

	while (1) {
		// Sleep until an external event occurs
		sleep();

		// Check to see if the event was an ibutton
		has_ibutton = 0;
		for (int i = 0; i < IBUTTON_LEN; i++) {
			has_ibutton |= ibutton[i];
		}

		if (has_ibutton) {
			ibutton_handled();
		}

		// Check to see if the event was a network message
	}

	return 0;
}

void sleep() {

}

