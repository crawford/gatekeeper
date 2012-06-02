require 'socket'

FETCH_ETHERNET_DOOR = '
	SELECT doors.name AS name, message_address AS dAddr, doors.id AS dID
	FROM doors, interfaces
	WHERE interface_id = interfaces.id AND
	      interfaces.name = "ethernet" AND
	      hardware_address = "%s"
'.freeze

module Gatekeeper
	class EthernetInterface < EM::Connection
		attr_accessor :receive_callback

		def initialize(config)
			@db = DB.new
			@door = nil
		end

		def send_message(message)
			puts "Ethernet: Sending #{message.dump}"
			send_data(message)
		end

		def post_init
			begin
				port, ip = Socket.unpack_sockaddr_in(get_peername)

				door = @db.query(FETCH_ETHERNET_DOOR, ip).first
				unless door
					puts "Unknown device connected from #{ip}"
					close_connection
					return
				end

				ApiServer.instance.register_ethernet(door[:dAddr], self)

				@door = door
				puts "'#{door[:name]}' device connected"

				num = door[:dAddr].to_i.chr
				send_data("D\001#{num}\n")

				ApiServer.instance.query_door_state(door[:dID])
			rescue Exception => e
				p e.backtrace
				close_connection
			end
		end

		def receive_data(data)
			puts "Received data from ethernet (#{data.dump}) length: #{data.length}"
			@receive_callback.call(data, @door[:dID])
		end

		def unbind
			puts '========================='
			puts "Connection to #{@door[:name]} Lost"  if     @door
			puts "Connection to unknown device closed" unless @door

			ApiServer.instance.clear_door_state(@door[:dID]) if @door
		end
	end
end
