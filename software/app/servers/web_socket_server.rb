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

			ApiServer.instance.state_changed_callbacks << method(:send_states)
		end

		def onopen
		end

		def onmessage(msg)
			command, payload, id = msg.split(':')
			command.upcase!

			unless command and payload
				send("Malformed instruction (Command:Payload[:Id])")
				return
			end

			case command
				when 'AUTH'
					@user = ApiServer.instance.authenticate_user(payload)
					unless @user
						send({:result => false, :error => "Invalid user key", :id => id}.to_json)
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
					send({:success => false, :error => "Unrecognized command '#{command}'"}.to_json)
			end
		end

		def onerror(error)
			p $@
			p error
		end

		def onclose
		end

		def send_states
			doors = ApiServer.instance.fetch_all_doors
			doors.each do |door|
				# This should actually be checked
				door[:pop]    = true
				door[:unlock] = true
				door[:lock]   = true
			end
			send({:states => doors}.to_json)
		end
	end
end
