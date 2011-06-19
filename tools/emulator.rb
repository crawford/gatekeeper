#!/usr/bin/ruby

class Emulator
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

	P_INVALID = 1.chr
	P_TIMEOUT = 2.chr

	TERMINATOR = "\n"
	MAX_PAYLOAD_LEN = 50

	def initialize(device)
		@msgbuf = ''
		@msgID = 0
		@locked = true
		@doorID = 0
		@access_list = Array.new
		@device = device
		@MSG_COMMANDS = { C_QUERY =>    method(:cmd_query),
		                  C_RESPONSE => method(:cmd_response),
		                  C_LOCK =>     method(:cmd_lock),
		                  C_UNLOCK =>   method(:cmd_unlock),
		                  C_POP =>      method(:cmd_pop),
		                  C_CLEAR =>    method(:cmd_clear),
		                  C_ADD =>      method(:cmd_add),
		                  C_STATUS =>   method(:cmd_status),
		                  C_IBUTTON =>  method(:cmd_ibutton),
		                  C_ERROR =>    method(:cmd_error),
		                  C_DOOR =>     method(:cmd_door)
		                }.freeze
	end

	def run
		loop do
			(r,w,x) = select([@device], [], [], 5)

			unless r.empty?
				read_message(@device.read)
			end
		end
	end

	def read_message(message)
		@msgbuf << message

		@msgbuf.split(TERMINATOR).each do |msg|
			if msg.empty?
				cmd_unknown(0)
			else
				parse_message(msg)
			end
		end

		if index = @msgbuf.rindex(TERMINATOR)
			@msgbuf = @msgbuf[(index + 1)..-1]
		end
	end

	private

	def parse_message(message)
		command, id, *payload = message.chars.to_a
		id = id[0]
		payload = payload.join

		if @MSG_COMMANDS.has_key?(command)
			@MSG_COMMANDS[command].call(id, payload)
		else
			cmd_unknown(id, payload)
		end
	end

	def send_response(id, payload = "S")
		send_message(C_RESPONSE, id, @doorID.chr + payload)
	end

	def send_message(command, id, payload)
		raise 'Invalid command' unless command.length == 1
		raise 'Invalid id' unless id.between?(0, 255)
		raise 'Invalid payload (too large)' unless payload.length <= MAX_PAYLOAD_LEN

		message = command + id.chr + payload
		p "Sending message - #{message}"
		@device.write message
	end

	def unlock_door
		@locked = false
		p "Unlocking door"
	end
	
	def lock_door
		@locked = true
		p "Locking door"
	end

	def pop_door
		@locked = false
		p "Popping door"
	end


	def cmd_unknown(id, payload)
		send_message(C_ERROR, 0, P_INVALID)
	end

	def cmd_query(id, payload)
		send_message(C_RESPONSE, id, (@locked and 'L' or 'U'))
	end

	def cmd_lock(id, payload)
		lock_door()
		send_response(id)
	end

	def cmd_unlock(id, payload)
		unlock_door()
		send_response(id)
	end

	def cmd_pop(id, payload)
		pop_door()
		send_response(id)
	end

	def cmd_clear(id, payload)
		@access_list = []
		p "Cleared access list"
		send_response(id)
	end

	def cmd_add(id, payload)
		@access_list << payload
		p "Access list: #{access_list}"
		send_response(id)
	end

	def cmd_status(id, payload)
		show_status(payload)
		send_response(id)
	end

	def cmd_ibutton(id, payload)
		p "Ignoring command (iButton)"
	end

	def cmd_response(id, payload)
		p "Ignoring command (Response)"
	end

	def cmd_error(id, payload)
		p "Ignoring command (Error)"
	end

	def cmd_door(id, payload)
		@doorID = payload[0]
		p "Changing door id to #{id}"
		send_response(id)
	end
end

if ARGS.size != 2 or (ARGS[1].lower != 'socket' and ARGS[1].lower != 'file')
	p "Usgae: ./emulator file_name ('file' | 'socket')"
end

case ARGS[0]
	when 'file'
		device = File.new(ARGS[0], 'r+', {:autoclose => false})
	when 'socket'
		device = UNIXSocket.new(ARGS[0])
end
e = Emulator.new(device)
e.start

e.read_message("Q\001\n")
e.read_message("U\002\n")
e.read_message("Q\003\n")
e.read_message("D\006\006\n")
e.read_message("L\004\n")
e.read_message("Q\005\n")
e.read_message("y\006\n")
