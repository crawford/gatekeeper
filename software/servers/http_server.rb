#TODO: super fast hack code

require 'http_parser'
require 'api_server'

module Gatekeeper
	class HttpServer < EM::Connection
		include ApiServer

		def initialize(config)
			super(config)
			@parser = Http::Parser.new
			@parser.on_headers_complete = proc do
				begin
					parse_request(@parser.request_url)
				rescue => e
					send_data('Exception occured: ' << e.to_s)
					close_connection_after_writing
					raise e
				end
			end
		end

		def receive_data(data)
			if @last_error.nil?
				@parser << data
			else
				send_data('Exception occured: ' << @last_error.to_s)
				close_connection_after_writing
			end
		end

		def parse_request(uri)
			uri = uri[1..-1].split('/')
			#uri[0] ||= 'index.html'
			case uri[0]
				#when 'index.html'
				#	File.open('../site/views/index.html') do |page|
				#		send_data(page.read)
				#	end
				when 'all_doors'
					send_data(fetch_all_doors)
				when 'door_state'
					id = uri[1].to_i
					res = fetch_door_state(id)
					res ||= 'Invalid or missing ID'

					send_data(res)
				when 'unlock'
					door = uri[1].to_i
					user = parse_and_auth(uri[2..-1])
					if user.nil?
						send_data('Invalid parameters')
					else
						do_action(user, :unlock, door) do |result|
							send_data(result)
						end
					end
				when 'favicon'
				else
					send_data('Invalid Command')
			end
			close_connection_after_writing
		end

		private

		def parse_and_auth(uri)
			case uri.size
				when 1
					ibutton = uri[0]
					return authenticate_user(ibutton)
				when 2
					username = uri[0]
					password = uri[1]
					return authenticate_user(username, password)
			end
		end
	end
end
