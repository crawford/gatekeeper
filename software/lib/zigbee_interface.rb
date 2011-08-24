require 'socket'

module Gatekeeper
	class ZigbeeInterface < EM::Connection
		attr_accessor :receive_callback

		def initialize
		end

		def send_message(address, message)
			puts "Zigbee: Sending #{message.dump} to #{address}"
			#send_data('ZB: ' + address + message)
			send_data(message)
		end

		def post_init
		end

		def receive_data(data)
			puts "Received data from zigzag (#{data.dump}) length: #{data.length}"
			@receive_callback.call(data, 1)
		end

		def unbind
			# We lost our connection to zigzag, sound the alarm
			puts '========================='
			puts 'Connection to Zigzag Lost'
			puts '========================='
		end
	end
end
