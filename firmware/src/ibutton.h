#ifndef IBUTTON_H
#define IBUTTON_H

#define IBUTTON_LEN 8

extern uint8_t ibutton[IBUTTON_LEN];

void init_ibutton();
void ibutton_handled();

#endif

