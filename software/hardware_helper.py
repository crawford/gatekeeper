from select import select

class HardwareHelper:
	pipe = None
	msgID = None

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

	TERMINATOR = '\n'



	def __init__(self, pipe):
		self.pipe = pipe
		self.msgID = 0

	def zID_for_dID(self, door):
		return 1

	def send_message(self, door, command, payload = ''):
		id = self.msgID
		self.msgID += 1
		self.pipe.write(command + chr(id) + payload + self.TERMINATOR)
		return id

	def wait_for_response(self, id):
		(r,w,x) = select([self.pipe], [], [], 5)
		if len(r):
			return self.pipe.readline()
		else:
			return self.pipe.readline()

	def query(self, door):
		id = self.send_message(door, self.C_QUERY)
		return self.wait_for_response(id)

