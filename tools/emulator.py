#!/usr/bin/python

from sys import argv
from select import select

C_QUERY = 'Q'
C_RESPONSE = 'R'
C_LOCK = 'L'
C_UNLOCK = 'U'
C_POP = 'P'
C_CLEAR = 'C'
C_ADD = 'A'
C_STATUS = 'S'
C_IBUTTON = 'I'
C_ERROR = 'E'
C_DOOR = 'D'

P_INVALID = chr(1)
P_TIMEOUT = chr(2)

TERMINATOR = '\n'
MAX_PAYLOAD_LEN = 50



def cmd_unknown(id, payload):
	send_message(C_ERROR, id, P_INVALID)

def cmd_query(id, payload):
	global locked
	send_message(C_RESPONSE, id, locked and 'L' or 'U')

def cmd_lock(id, payload):
	lock_door()
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')

def cmd_unlock(id, payload):
	unlock_door()
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')

def cmd_pop(id, payload):
	pop_door()
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')

def cmd_clear(id, payload):
	global access_list
	access_list = []
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')
	print access_list

def cmd_add(id, payload):
	global access_list
	access_list.append(payload)
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')
	print access_list

def cmd_status(id, payload):
	show_status(payload)
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')

def cmd_ibutton(id, payload):
	print 'Ignoring command (iButton)'

def cmd_response(id, payload):
	print 'Ignoring command (Response)'

def cmd_error(id, payload):
	print 'Ignoring command (Error)'

def cmd_door(id, payload):
	global dID
	dID = payload
	global dID
	send_message(C_RESPONSE, id, chr(dID) + 'S')


MSG_COMMANDS = {C_QUERY:    cmd_query,
                C_RESPONSE: cmd_response,
				C_LOCK:     cmd_lock,
				C_UNLOCK:   cmd_unlock,
				C_POP:      cmd_pop,
				C_CLEAR:    cmd_clear,
				C_ADD:      cmd_add,
				C_STATUS:   cmd_status,
				C_IBUTTON:  cmd_ibutton,
				C_ERROR:    cmd_error,
				C_DOOR:     cmd_door}



def read_message(message):
	global msgbuf
	msgbuf += message

	while TERMINATOR in msgbuf:
		msg = msgbuf[:msgbuf.find(TERMINATOR)]
		msgbuf = msgbuf[msgbuf.find(TERMINATOR) + 1:]
		if len(msg):
			parse_message(msg)
		else:
			send_message(C_ERROR, 0, P_INVALID)


def parse_message(message):
	cmd = MSG_COMMANDS.get(message[0], cmd_unknown)
	m_id = message[1]
	m_id = 1
	m_payload = message[2:]
	cmd(m_id, m_payload)

def send_message(command, id, payload):
	if len(command) != 1:
		raise(ValueError('Invalid command'))

	if id < 0 or id > 255:
		raise(ValueError('Invalid id'))

	if len(payload) > MAX_PAYLOAD_LEN:
		raise(ValueError('Payload too large'))

	print 'Sending message -', command + chr(id) + payload

def read_ibutton(id):
	global msgid
	send_message(C_IBUTTON, msgid, id)
	print 'Waiting for response from server...'
	#Actually check
	msgid += 1
	print 'Response timed out. Failing to local access list'
	show_status(P_TIMEOUT)
	if id in access_list:
		pop_door()

def show_status(code):
	print 'Showing status -', code

def unlock_door():
	global locked
	locked = False
	print 'Unlocking door'

def lock_door():
	global locked
	locked = True
	print 'Locking door'

def pop_door():
	global locked
	locked = True
	print 'Popping door'


def __main__():
	if len(argv) != 2:
		print 'Usage:', argv[0], 'fifo_name'
		quit()

	device = open(argv[1], 'r+')

	while True:
		(r,w,x) = select([device], [], [], 5)
		if len(r):
			msg = device.readline()
			read_message(msg)




msgbuf = ''
msgid = 1
locked = True
access_list = []
dID = 0

__main__()

#parse_message('Q\x01')
#parse_message('U\x02')
#parse_message('Q\x03')
#parse_message('L\x04')
#parse_message('Q\x05')
#parse_message('P\x06')
#parse_message('Q\x07')
#parse_message('S\x084')
#parse_message('I\x0901234567')
#parse_message('E\x0A3')
#parse_message('R\x0BP')
#parse_message('Z\x0CP')
#parse_message('0\x0Dlsdf')
#parse_message('A\x0EAlex')
#parse_message('A\x0FSean')
#parse_message('C\x10')
#
#read_ibutton('bob')
#parse_message('A\x11bob')
#read_ibutton('bob')

#read_message('A');
#read_message('\x0F');
#read_message('Sea');
#read_message('n\nQ\x01\n');
