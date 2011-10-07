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

			#@user = User.new(1, false, "test", "000")
			@user = nil
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
					#TODO: authenticate the user
					@user = User.new({:uuid => 'alex', :admin => false, :name => "Test User", :ibutton => "00000", :id => 1})
					send({:result => true, :error => nil, :id => id}.to_json)

					doors = ApiServer.instance.fetch_all_doors
					doors.each do |door|
						# This should actually be checked
						door[:pop]    = true
						door[:unlock] = false
						door[:lock]   = true
					end
					send({:states => doors}.to_json)
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
	end
end
