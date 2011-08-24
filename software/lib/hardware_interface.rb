require 'mysql2'
require 'singleton'
require 'message_process'
require 'zigbee_interface'
require 'ldap'

module Gatekeeper
	class HardwareInterface
		include Singleton

		FETCH_INTERFACE_FROM_DID = '
			SELECT interfaces.name AS interface
			FROM doors, interfaces
			WHERE doors.interface_id = interfaces.id AND doors.id = %d
		'.freeze
		FETCH_ACCESS_LIST_FOR_DID = '
			SELECT users.id AS id
			FROM access_lists, users
			WHERE door_id = %d AND user_id = users.id
		'.freeze
		INSERT_INTO_ACCESS_LIST = '
			INSERT INTO access_lists (user_id, door_id)
			VALUES %s
		'.freeze
		CLEAR_ACCESS_LIST = '
			DELETE FROM access_lists
			WHERE door_id = %d
		'.freeze

		C_QUERY = 'Q'.freeze
		C_RESPONSE = 'R'.freeze
		C_LOCK = 'L'.freeze
		C_UNLOCK = 'U'.freeze
		C_POP = 'P'.freeze
		C_CLEAR = 'C'.freeze
		C_ADD = 'A'.freeze
		C_STATUS = 'S'.freeze
		C_IBUTTON = 'I'.freeze
		C_ERROR = 'E'.freeze
		C_DOOR = 'D'.freeze


		def initialize
			@zigbee = nil
			@ethernet = nil
			@ldap = Ldap.new
			@db = nil
			@msgid = 0
			@fibers = {}
		end

		def setup(db, zigbee)
			@db = db
			@zigbee = zigbee
			@zigbee.receive_callback = method(:process_message)
		end

		def process_message(data, sender)
			cmd = data[0]
			msgid = data[1]
			payload = data[2..-1]

			puts "CMD: #{cmd.dump}"
			puts "MSGID: #{msgid.dump}"
			puts "PAYLOAD: #{payload.dump}"

			if (payload[-1] != "\n")
				puts "Invalid message (#{data.dump})"
				return
			end

			case cmd
				when C_RESPONSE
					key = "#{sender},#{msgid}"
					if @fibers.has_key?(key)
						@fibers.delete(key).resume(payload)
					else
						puts "Got a response for a non-existant fiber"
					end
				when C_IBUTTON
					puts "IButton (#{payload})"
					#TODO: process the ibutton
				when C_ERROR
					puts "An error occured on door #{sender} (#{payload.dump})"
				else
					puts "Unexpected message (#{data.dump})"
			end
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
			msg = command + @msgid.to_s + payload.to_s + "\n"
			@msgid += 1

			puts "Sending message(#{msg.dump}) to interface(#{interface})"
			interface.send_message('ZIGBEE', msg)
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
