require 'mysql2'
require 'singleton'
require 'message_process'
require 'zigbee_interface'
require 'ethernet_pool'
require 'ldap'

module Gatekeeper
	class HardwareInterface
		FETCH_INTERFACE_AND_ADDRESS_FROM_DID = '
			SELECT interfaces.name AS interface, doors.message_address AS address
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


		def initialize(api_server)
			@api_server = api_server
			@zigbee = nil
			@ethernet = EthernetPool.new
			@db = DB.new
			@ldap = Ldap.new
			@msgid = 1
			@fibers = {}
		end

		def register_ethernet(address, ethernet)
			ethernet.receive_callback = method(:process_message)
			@ethernet.register_interface(address, ethernet)
		end

		def zigbee=(zigbee)
			@zigbee = zigbee
			@zigbee.receive_callback = method(:process_message)
		end

		def process_message(data, sender)
			cmd = data[0]
			msgid = data.getbyte(1)
			payload = data[2..-1]

			#puts "CMD: #{cmd.dump}"
			#puts "MSGID: #{msgid.dump}"
			#puts "PAYLOAD: #{payload.dump}"

			# Check for the trailing newline and remove it if its there
			if payload and payload[-1] == "\n"
				payload = payload[0..-2]
			else
				puts "Invalid message (#{data.dump})"
				return
			end

			case cmd
				when C_RESPONSE
					key = "#{sender},#{msgid.to_s}"
					if @fibers.has_key?(key)
						@fibers.delete(key).resume(payload)
					else
						puts "Got a response for a non-existant fiber (key: #{key})"
					end
				when C_IBUTTON
					door_addr = payload[0].ord
					ibutton   = payload[1..-1]
					puts "IButton (#{ibutton}) from door (#{door_addr})"

					info = @ldap.info_for_ibutton(ibutton)
					p info
					return unless info

					begin
						user = @api_server.create_user_by_info(info)
						@api_server.do_action(user, :pop, sender)
					rescue MySql2::Error
						puts "Failed to connect to database"
					end
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
				user.ibutton
			end

			fiber = MessageProcess.new do
				# The list was updated on the hardware, now update the database
				values = users.collect do |user|
					"(#{user.uuid}, #{dID})"
				end
				begin
					@db.query(INSERT_INTO_ACCESS_LIST, values.join(','))
				rescue MySql2::Error
					puts 'Connection to database failed'
				end
			end

			fiber.callback = callback
			send_and_register(fiber, dID, C_ADD, iButtons.join(','))
		end


		def remove_from_al(dID, users, callback = nil)
			existing = @db.fetch(:id, FETCH_ACCESS_LIST_FOR_DID, dID) || []
			existing -= users if users

			# Look up iButtons
			iButtons = existing.collect do |user|
				user.ibutton
			end

			fiber = MessageProcess.new do
				# The list was cleared, so add our new iButtons
				begin
					@db.query(CLEAR_ACCESS_LIST, dID)
				rescue MySql2::Error
					puts 'Connection to database failed'
				end

				unless iButtons.empty?
					send_and_register(Fiber.current, dID, C_ADD, iButtons.join(','))
					Fiber.yield

					# The new iButtons were saved so update the DB
					values = existing.collect do |user|
						"('#{user.uuid}', '#{dID}')"
					end
					begin
						@db.query(INSERT_INTO_ACCESS_LIST, values.join(','))
					rescue MySql2::Error
						puts 'Connection to database failed'
					end
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

			begin
				interface, address = get_interface_for_dID(dID)
			rescue MySql2::Error
				puts 'Connection to database failed'
				fiber.fail
			end

			if interface
				begin
					send_message(interface, address, command, payload)
				rescue => e
					puts e.backtrace.to_s
					fiber.fail
				else
					register_fiber(fiber, key)
				end
			else
				puts "No interface for dID (#{dID})"
				fiber.fail
			end
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


		# Builds and sends a message to the specified interface and address

		def send_message(interface, address, command, payload)
			msg = command + @msgid.chr + payload.to_s + "\n"
			@msgid = (@msgid + 1) % 256
			@msgid += 1 if (@msgid == 0 or @msgid == 10) #Skip \0 and \n

			puts "Sending message(#{msg.dump}) to interface(#{interface})"
			interface.send_message(address.to_s, msg)
		end


		# Return the interface object and address associated with the specified dID

		def get_interface_for_dID(dID)
			result = @db.query(FETCH_INTERFACE_AND_ADDRESS_FROM_DID, dID).first
			return nil unless result
			interface = case result[:interface]
				when 'zigbee' then @zigbee
				when 'ethernet' then @ethernet
			end
			[interface, result[:address]]
		end
	end
end
