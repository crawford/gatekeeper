CC=avr-gcc
CFLAGS=-g -Wall -Os -std=c99 -mmcu=atmega168
OBJ2HEX=avr-objcopy
TARGET=gatekeeper

all: $(TARGET).hex

program: $(TARGET).hex
	cp $(TARGET).hex /media/shared

%.o: %.c
	$(CC) $(CFLAGS) $< -c -o $@

$(TARGET).obj: leds.o motor.o main.o onewire.o ibutton.o
	$(CC) $(CFLAGS) $? -o $@

%.hex: %.obj
	$(OBJ2HEX) -R .eeprom -O ihex $< $@

clean:
	rm -f *.hex *.obj *.o
