require 'hardware_interface'
require 'event_machine'

class ZigzagClient
	def initialize(config)
		@hardware = HardwareInterface.instance
	end

	def post_init
	end

	def receive_data(data)
	end

	def unbind
		# We lost our connection to zigzag, sound the alarm
	end
end
