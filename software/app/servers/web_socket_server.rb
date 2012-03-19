require 'em-websocket'
require 'user'

module Gatekeeper
	class WebSocketServer < EM::WebSocket::Connection
		def initialize(options)
			EM::WebSocket::Connection.instance_method(:initialize).bind(self).call(options)

			@onopen    = method(:onopen)
			@onmessage = method(:onmessage)
			@onerror   = method(:onerror)
			@onclose   = method(:onclose)

			@user = nil
		end

		def onopen
			ApiServer.instance.state_changed_callbacks << method(:send_states)
		end

		def onmessage(msg)
			begin
				command, payload, id = msg.split(':')
				command.upcase!

				unless command and payload
					send({:success => false, :error => "Malformed instruction (Command:Payload[:Id])"}.to_json)
					return
				end

				case command
					when 'AUTH'
						@user = ApiServer.instance.authenticate_user(payload)
						unless @user
							send({:result => false, :error => "Invalid user key", :id => id}.to_json)
							close_connection_after_writing
							return
						end

						send({:result => true, :error => nil, :id => id}.to_json)
						send_states
					when 'POP'
						ApiServer.instance.do_action(@user, :pop, payload.to_i) do |result|
							send(result.merge({:id => id}).to_json)
						end
					when 'LOCK'
						ApiServer.instance.do_action(@user, :lock, payload.to_i) do |result|
							send(result.merge({:id => id}).to_json)
						end
					when 'UNLOCK'
						ApiServer.instance.do_action(@user, :unlock, payload.to_i) do |result|
							send(result.merge({:id => id}).to_json)
						end
					else
						send({:success => false, :error => "Unrecognized command '#{command}'", :id => id}.to_json)
				end
			rescue DBConnectionError => e
				send({:success => false, :error => e.to_s, :id => id}.to_json)
			end
		end

		def onerror(error)
			p $@
			p error
		end

		def onclose
			ApiServer.instance.state_changed_callbacks.delete(method(:send_states))
		end

		def send_states
			return unless @user
			doors = ApiServer.instance.fetch_all_doors(@user)
			send({:states => doors}.to_json)
		end
	end
end
