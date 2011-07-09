#TODO: super fast hack code
module Gatekeeper
	class ControlServer < EM::Connection
		PROMPT = "\n> "

		def post_init
			send_data PROMPT
		end

		def receive_data(data)
			case data.strip.downcase
				when 'stop' then EM.stop
				else send_data 'Unknown command'
			end
			send_data PROMPT
		end
	end
end
