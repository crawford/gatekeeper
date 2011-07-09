module Gatekeeper
	class ControlServer < EM::Connection
		PROMPT      = "\n> "
		CMD_STOP    = "stop"
		MSG_UNKNOWN = "Unknown command"

		def post_init
			send_data PROMPT
		end

		def receive_data(data)
			case data.strip.downcase
				when CMD_STOP then EM.stop
				else send_data MSG_UNKNOWN
			end
			send_data PROMPT
		end
	end
end
