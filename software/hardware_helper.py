from select import select
from Queue import Queue
from threading import Thread, Timer

class HardwareHelper(Thread):
	pipe = None
	msgID = None
	running = None
	ibutton_callback = None
	response_callbacks = None
	door_states = None

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
	C_SUCCESS = 'Y'

	R_CANCEL = 1
	R_TIMEOUT = 2

	TERMINATOR = '\n'
	PIPE_TIMEOUT = 5
	RESPONSE_TIMEOUT = 5



	def __init__(self, pipe, callback):
		super(HardwareHelper, self).__init__()
		self.pipe = pipe
		self.msgID = 0
		self.running = False
		self.ibutton_callback = callback
		self.response_callbacks = {}
		self.door_states = {}

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

				# If its a response, call the appropriate callback
				if msg[0] == C_RESPONSE:
					mID = msg[1]
					dID = msg[2]
					key = (mID, dID)
					response = msg[3:]

					value = self.response_callbacks.get(key)
					if value:
						(callback,timer,followup) = value
						timer.cancel()
						del self.response_callbacks[key]
						if followup:
							followup(response)
						if callback:
							callback(response)
					
					continue

				# This shouldn't get called
				print 'Received an invalid message (', msg, ')'

	def stop(self):
		self.running = False

	def fetch_access_list(self, dID):
		return {}

	def update_al_add(self, dID, items):
		pass
	
	def update_al_remove(self, dID, items):
		pass

	def update_al_clear(self, dID, items):
		pass

	def fetch_zID_for_dID(self, dID):
		return 1

	def send_message(self, dID, command, payload = ''):
		id = self.msgID
		self.msgID += 1
		self.pipe.write(command + chr(id) + payload + self.TERMINATOR)
		return id

	def register_response_callback(self, key, callback, followup):
		prev = self.response_callbacks.get(key)
		if prev:
			(p_callback,p_timer,followup) = prev
			p_timer.cancel()
			p_callback(self.R_CANCEL)

		timer = Timer(self.RESPONSE_TIMEOUT, lambda:callback(self.R_TIMEOUT))
		self.response_callbacks[key] = (callback,timer,followup)
		timer.start()
	
	def state_followup(self, response, dID):
		if not response == self.R_CANCEL and not response == self.R_TIMEOUT:
			self.door_states[dID] = response

	def add_followup(self, response, dID, iButtons):
		if response == self.C_SUCCESS:
			#Save iButtons to the DB
			pass

	def remove_followup_1(self, response, dID, iButtons):
		if response == self.C_SUCCESS:
			#Calculate the new list of iButtons
			ibutton_str = ''
			#Clear the values from the DB
			mID = self.send_message(dID, self.C_ADD, ibutton_str)
			followup = lambda r:self.remove_followup_2(r, dID, iButtons)
			self.register_response_callback((dID, mID), callback, followup)

	def remove_followup_2(self, response, dID, iButtons):
		if response == self.C_SUCCESS:
			#Save iButtons to the DB
			pass

	def clear_followup(self, response, dID):
		if response == self.C_SUCCESS:
			#Clear the iButtons from the DB
			pass


#==================#
# Public Functions #
#==================#

	def query(self, dID, callback = None):
		state = self.door_states.get(dID)
		if state:
			callback(state)
		else:
			mID = self.send_message(dID, self.C_QUERY)
			followup = lambda r:self.state_followup(r, dID)
			self.register_response_callback((dID, mID), callback, followup)

	def lock(self, dID, callback = None):
		mID = self.send_message(dID, self.C_LOCK)
		followup = lambda r:self.state_followup(r, dID)
		self.register_response_callback((dID, mID), callback, followup)

	def unlock(self, dID, callback = None):
		mID = self.send_message(dID, self.C_UNLOCK)
		followup = lambda r:self.state_followup(r, dID)
		self.register_response_callback((dID, mID), callback, followup)

	def pop(self, dID, callback = None):
		mID = self.send_message(dID, self.C_POP)
		followup = lambda r:self.state_followup(r, dID)
		self.register_response_callback((dID, mID), callback, followup)

	def add_to_al(self, dID, iButtons, callback = None):
		ibutton_str = ','.join(iButtons)
		mID = self.send_message(dID, self.C_ADD, ibutton_str)
		followup = lambda r:self.add_followup(r, dID, iButtons)
		self.register_response_callback((dID, mID), callback, followup)

	def remove_from_al(self, dID, iButtons, callback = None):
		mID = self.send_message(dID, self.C_CLEAR)
		followup = lambda r:self.remove_followup_1(r, dID, iButtons)
		self.register_response_callback((dID, mID), None, followup)

	def clear_al(self, dID, callback = None):
		mID = self.send_message(dID, self.C_CLEAR)
		followup = lambda r:self.clear_followup(r, dID)
		self.register_response_callback((dID, mID), callback, followup)

	def show_status(self, dID, status, callback = None):
		mID = self.send_message(dID, self.C_STATUS, chr(status))
		self.register_response_callback((dID, mID), callback, None)

