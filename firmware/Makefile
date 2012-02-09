CC      = avr-gcc
CFLAGS  = -g -Wall -Os -std=c99 -mmcu=atmega168
OBJ2HEX = avr-objcopy
TARGET  = gatekeeper


BUILD_DIR = build
SRC_DIR   = src
SRC_FILES = leds.c      \
            motor.c     \
            main.c      \
            onewire.c   \
            ibutton.c
OBJS = $(SRC_FILES:%.c=$(BUILD_DIR)/%.o)

ELF = $(BUILD_DIR)/$(TARGET).elf
HEX = $(BUILD_DIR)/$(TARGET).hex

all: $(HEX)

program: $(HEX)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -c -o $@

$(ELF): $(OBJS)
	$(CC) $(CFLAGS) $? -o $@

%.hex: %.elf
	$(OBJ2HEX) -R .eeprom -O ihex $< $@

clean:
	rm -f $(OBJS)
	rm -f $(ELF)
	rm -f $(HEX)
