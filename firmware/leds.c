#include "leds.h"
#include "utils.h"
#include <avr/io.h>

void _isr_timer();

volatile int red_flash_count;
volatile int green_flash_count;

static const int GREEN_LED_PIN = 6;
static const int RED_LED_PIN   = 5;


void init_leds() {
	// Turn off the leds
	WRITE_LOW(&PORTD, RED_LED_PIN);
	WRITE_LOW(&PORTD, GREEN_LED_PIN);

	// Set the pins to output
	DDRD |= (1 << GREEN_LED_PIN);
	DDRD |= (1 << RED_LED_PIN);

	// Clear the flash codes
	red_flash_count   = 0;
	green_flash_count = 0;

	// Set up the timer for the leds
}

void show_network_error() {
	red_flash_count   = 4;
	green_flash_count = 4;
	// Enabled the timer
}

void show_status_code(int code) {
	red_flash_count = code * 2;
	// Enabled the timer
}

void _isr_timer() {
	// Flash the red LED
	if (red_flash_count) {
		if (red_flash_count & 1) {
			WRITE_LOW(&PORTD, RED_LED_PIN);
		} else {
			WRITE_HIGH(&PORTD, RED_LED_PIN);
		}

		red_flash_count--;
	}

	// Flash the green LED
	if (green_flash_count) {
		if (green_flash_count & 1) {
			WRITE_LOW(&PORTD, GREEN_LED_PIN);
		} else {
			WRITE_HIGH(&PORTD, GREEN_LED_PIN);
		}

		green_flash_count--;
	}

	if (!green_flash_count && !red_flash_count) {
		//Disable timer
	}
}

