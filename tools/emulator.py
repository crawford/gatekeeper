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

P_INVALID = '1'


def cmd_unknown(id, payload):
	send_message(C_ERROR, id, P_INVALID)

def cmd_query(id, payload):
	global locked
	send_message(C_RESPONSE, id, locked and 'L' or 'U')

def cmd_lock(id, payload):
	global locked
	locked = True
	print 'Locking door'

def cmd_unlock(id, payload):
	global locked
	locked = False
	print 'Unlocking door'

def cmd_pop(id, payload):
	global locked
	locked = True
	print 'Popping door'

def cmd_clear(id, payload):
	access_list = []
	print access_list

def cmd_add(id, payload):
	access_list.append(payload)
	print access_list

def cmd_status(id, payload):
	print 'Showing status -', payload

def cmd_ibutton(id, payload):
	print 'Ignoring command (iButton)'

def cmd_response(id, payload):
	print 'Ignoring command (Response)'

def cmd_error(id, payload):
	print 'Ignoring command (Error)'


MSG_COMMANDS = {C_QUERY:    cmd_query,
                C_RESPONSE: cmd_response,
				C_LOCK:     cmd_lock,
				C_UNLOCK:   cmd_unlock,
				C_POP:      cmd_pop,
				C_CLEAR:    cmd_clear,
				C_ADD:      cmd_add,
				C_STATUS:   cmd_status,
				C_IBUTTON:  cmd_ibutton,
				C_ERROR:    cmd_error}

MAX_PAYLOAD_LEN = 50

msgbuf = '';
locked = True
access_list = []



def parse_message(message):
	cmd = MSG_COMMANDS.get(message[0], cmd_unknown)
	m_id = message[1]
	m_payload = message[2:]
	cmd(m_id, m_payload)

def send_message(command, id, payload):
	if len(command) != 1:
		raise(ValueError('Invalid command'))

	#if int(id) < 0 or id > 255:
	#	raise(ValueError('Invalid id'))

	if len(payload) > MAX_PAYLOAD_LEN:
		raise(ValueError('Payload too large'))

	print 'Sending message -', command + id + payload


parse_message('Qa')
parse_message('Ub')
parse_message('Qc')
parse_message('Ld')
parse_message('Qe')
parse_message('Pf')
parse_message('Qg')
parse_message('Sh4')
parse_message('Ii01234567')
parse_message('Ej3')
parse_message('RkP')
parse_message('ZlP')
parse_message('0mlsdf')
parse_message('AnAlex')
parse_message('AoSean')
parse_message('Cp')

