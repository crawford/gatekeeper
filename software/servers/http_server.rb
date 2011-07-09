#TODO: super fast hack code

require 'http_parser'
require 'api_server'

module Gatekeeper
	class HttpServer < EM::Connection
		include ApiServer

		def initialize(config)
			super (config)
			@parser = Http::Parser.new
			@parser.on_headers_complete = proc do
				begin
					parse_request(@parser.request_url)
				rescue => e
					send_data('Exception occured:' << e.to_s)
					close_connection_after_writing
					raise e
				end
			end
		end

		def receive_data(data)
			@parser << data
		end

		def parse_request(uri)
			uri = uri[1..-1].split('/')
			case uri[0]
				when 'all_doors'
					send_data(fetch_all_doors)
					close_connection_after_writing
				when 'door_state'
					id = uri[1].to_i
					res = fetch_door_state(id)
					res ||= 'Invalid or missing ID'

					send_data(res)
					close_connection_after_writing
				when 'unlock'
					door = uri[1].to_i
					user = parse_and_auth(uri[2..-1])
					if user.nil?
						send_data('Invalid parameters')
						close_connection_after_writing
						return
					end

					do_action(user, :unlock, door) do |result|
						send_data(result)
						close_connection_after_writing
					end
				when 'favicon'
				else
					send_data('Unknown')
					close_connection_after_writing
			end
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
