module Gatekeeper
	class ZigbeeInterface
		def send_message(address, message)
			'ZB: ' << address << message
		end
	end
end
