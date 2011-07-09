module Gatekeeper
	class ZigbeeProtocol
		def build_packet(address, message)
			'ZB: ' << address << message
		end
	end
end
