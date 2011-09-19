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
					send({:states => [
					       {
					         :door_id => 1,
					         :state => 'unlocked',
					         :door_name => 'Research Room',
					         :lock => true,
					         :unlock => false,
					         :pop => true
					       },
					       {
					         :door_id => 2,
					         :state => 'locked',
					         :door_name => 'Poop Room',
					         :lock => true,
					         :unlock => true,
					         :pop => true
					       }
					       ]
					    }.to_json)
				when 'POP'
					do_action(@user, :pop, payload.to_i) do |result|
						send(result.merge({:id => id}).to_json)
					end
				when 'LOCK'
					do_action(@user, :lock, payload.to_i) do |result|
						send(result.merge({:id => id}).to_json)
					end
				when 'UNLOCK'
					do_action(@user, :unlock, payload.to_i) do |result|
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
