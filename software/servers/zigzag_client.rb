require 'eventmachine'

module Gatekeeper
	class ZigzagClient < EM::Connection
		def initialize(config)
			super(123)

			db = Mysql2::Client.new(config[:database])
			@hardware = HardwareInterface.instance
			@hardware.setup(db)
		end

		def post_init
		end

		def receive_data(data)
		end

		def unbind
			# We lost our connection to zigzag, sound the alarm
		end
	end
end
