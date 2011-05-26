from select import select
from Queue import Queue
from threading import Thread, Lock, Condition

class HardwareHelper(Thread):
	pipe = None
	response = None
	msgID = None
	running = None
	ibutton_callback = None
	res_lock = None

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
	PIPE_TIMEOUT = 5
	RESPONSE_TIMEOUT = 5



	def __init__(self, pipe, callback):
		super(HardwareHelper, self).__init__()
		self.pipe = pipe
		self.msgID = 0
		self.running = False
		self.ibutton_callback = callback
		self.res_cond = Condition()
		self.res_cond.acquire()

	def run(self):
		# Monitor the hardware pipe for messages
		self.running = True
		while self.running:
			(r,w,x) = select([self.pipe], [], [], self.PIPE_TIMEOUT)
			if len(r):
				msg = self.pipe.readline()
				if msg[-1] == '\n':
					msg = msg[:-1]

				# If its an iButton message, call the handler
				if msg[0] == C_IBUTTON:
					# Don't send the command and the ID
					self.ibutton_callback(msg[2:])
					continue

				# If its a response, save it
				if msg[0] == C_RESPONSE:
					self.response = msg[1:]
					self.res_cond.notifyAll()
					continue

				# This shouldn't get called
				print 'Received an invalid message (', msg, ')'

	def stop(self):
		self.running = False

	def zID_for_dID(self, door):
		return 1

	def send_message(self, door, command, payload = ''):
		id = self.msgID
		self.msgID += 1
		self.pipe.write(command + chr(id) + payload + self.TERMINATOR)
		return id

	def wait_for_response(self, id):
		self.res_cond.wait(self.RESPONSE_TIMEOUT)

		if not self.response:
			return None

		if self.response[0] != id:
			return None

		# Return the payload
		return self.response[1:]
	
	def query(self, door):
		self.response = ''
		id = self.send_message(door, self.C_QUERY)
		return self.wait_for_response(id)

