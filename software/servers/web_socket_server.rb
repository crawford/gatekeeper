require 'em-websocket'

module Gatekeeper
	class WebSocketServer < EM::WebSocket::Connection
		def initialize(options)
			super(options)

			@onopen    = method(:onopen)
			@onmessage = method(:onmessage)
			@onerror   = method(:onerror)
			@onclose   = method(:onclose)
		end

		def onopen
			puts "OPEN"
		end

		def onmessage(msg)
			p msg
		end

		def onerror(error)
			p error
		end

		def onclose
			puts "CLOSE"
		end
	end
end
