#include <avr/io.h>
#include "leds.h"
#include "motor.h"


int main() {
	init_leds();
	init_motor();

	return 0;
}
