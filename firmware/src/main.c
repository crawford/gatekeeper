#include <avr/sleep.h>
#include "leds.h"
#include "motor.h"
#include "ibutton.h"

void handle_ibutton();
void handle_message();

int main() {
	init_leds();
	init_motor();
	init_ibutton();
	//init_xbee();

	set_sleep_mode(SLEEP_MODE_PWR_DOWN);

	uint8_t has_ibutton;

	while (1) {
		// Sleep until an external event occurs
		sleep_enable();
		sleep_cpu();
		sleep_disable();

		// Check to see if the event was an ibutton
		has_ibutton = 0;
		for (int i = 0; i < IBUTTON_LEN; i++) {
			has_ibutton |= ibutton[i];
		}

		if (has_ibutton) {
			handle_ibutton();
			ibutton_handled();
		}

		// Check to see if the event was a network message
	}

	return 0;
}

void handle_ibutton() {

}

void handle_messsage() {

}

