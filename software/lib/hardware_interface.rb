require 'mysql2'
#require 'message_process'

module Gatekeeper
	class HardwareInterface
		FETCH_INTERFACE_FROM_DID = '
			SELECT interfaces.name AS interface
			FROM doors, interfaces
			WHERE doors.interface_id = interfaces.id AND doors.id = %d
		'
		FETCH_ACCESS_LIST_FOR_DID = '
			SELECT users.id AS id
			FROM access_lists, users
			WHERE door_id = %d AND user_id = users.id
		'
		INSERT_INTO_ACCESS_LIST = '
			INSERT INTO access_lists (user_id, door_id)
			VALUES %s
		'
		CLEAR_ACCESS_LIST = '
			DELETE FROM access_lists
			WHERE door_id = %d
		'

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


		def initialize(db)
			@zigbee = ZigbeeInterface.new
			@ethernet = nil
			@db = db
			@ldap = Ldap.new
			@msgid = 0
			@fibers = {}
		end


		def query(dID, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_QUERY)
		end


		def lock(dID, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_LOCK)
		end


		def unlock(dID, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_UNLOCK)
		end


		def pop(dID, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_POP)
		end


		def clear_al(dID, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_CLEAR)
		end


		def add_to_al(dID, users, callback = nil)
			# YOU WILL GET DUPLICATES
			# Look up iButtons
			iButtons = users.collect do |user|
				@ldap.ibutton_for_user(user)
			end

			fiber = MessageProcess.new do
				# The list was updated on the hardware, now update the database
				values = users.collect do |user|
					"(#{user}, #{dID})"
				end
				db_query(INSERT_INTO_ACCESS_LIST, values.join(','))
			end

			fiber.callback = callback
			send_and_register(fiber, dID, C_ADD, iButtons.join(','))
		end


		def remove_from_al(dID, users, callback = nil)
			existing = db_fetch(:id, FETCH_ACCESS_LIST_FOR_DID, dID) || []
			existing -= users if users

			# Look up iButtons
			iButtons = existing.collect do |user|
				@ldap.ibutton_for_user(user)
			end

			fiber = MessageProcess.new do
				# The list was cleared, so add our new iButtons
				db_query(CLEAR_ACCESS_LIST, dID)

				unless iButtons.empty?
					send_and_register(Fiber.current, dID, C_ADD, iButtons.join(','))
					Fiber.yield

					# The new iButtons were saved so update the DB
					values = existing.collect do |user|
						"('#{user}', '#{dID}')"
					end
					db_query(INSERT_INTO_ACCESS_LIST, values.join(','))
				end
			end

			fiber.callback = callback
			send_and_register(fiber, dID, C_CLEAR)
		end


		def show_status(dID, status, callback = nil)
			fiber = MessageProcess.new
			fiber.callback = callback
			send_and_register(fiber, dID, C_STATUS, status)
		end

		private

		# Builds and sends a message, and registers that fiber to the message

		def send_and_register(fiber, dID, command, payload = '')
			key = "#{dID},#{@msgid.to_s}"
			register_fiber(fiber, key)

			send_message(dID, command, payload)
		end


		# Registers the fiber to the specified key (killing any old fibers)

		def register_fiber(fiber, key)
			old = @fibers[key]
			if old
				old.cancel
			end

			fiber.cleanup = Proc.new do
				@fibers.delete(key)
			end
			@fibers[key] = fiber

		end


		# Builds and sends a message to the specified dID

		def send_message(dID, command, payload)
			interface = get_interface_for_dID(dID)
			msg = command << @msgid.to_s << payload << "\n"
			@msgid += 1

			puts "Sending message(#{msg}) to interface(#{interface})"
			#TODO: actually send a message

			v = @msgid - 1
			EM::Timer.new(1) do
				@fibers.delete("#{dID},#{v}").resume
			end
		end


		# Return the interface object associated with the specified dID

		def get_interface_for_dID(dID)
			case db_fetch(:interface, FETCH_INTERFACE_FROM_DID, dID)
				when 'zigbee' then @zigbee
				when 'ethernet' then @ethernet
			end
		end


		# Executes the query with substituted args and returns the specified
		# attributes or nil if there are no results.

		def db_fetch(attribute, query, *args)
			results = db_query(query, *args)
			return if results.size == 0

			out = []
			results.each(:symbolize_keys => true) do |result|
				out << result[attribute]
			end
			return out.first if out.size == 1
			out
		end


		# Substitutes the args into the query and executes it.

		def db_query(query, *args)
			@db.query(query % args)
		end
	end
end
