module Gatekeeper
	class EthernetPool
		def initialize
			@pool = {}
		end

		def register_interface(address, interface)
			@pool[address] = interface
		end

		def send_message(address, message)
			if @pool.has_key?(address)
				@pool[address].send_message(message)
			else
				#TODO Doors should be able to be offline without crashing
				fail 'Unknown address (is the door offline)'
			end
		end
	end
end
