#TODO: super fast hack code

require 'http_parser'
require 'api_server'

module Gatekeeper
	class HttpServer < EM::Connection

		def initialize(config)
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
			@parser << data
		end

		def parse_request(uri)
			uri = uri[1..-1].split('/')
			case uri[0]
				when 'all_doors'
					# /all_doors
					send_data(fetch_all_doors.to_json)
				when 'door_state'
					# /door_state/(door id)
					id = uri[1].to_i
					res = fetch_door_state(id)
					res ||= 'Invalid or missing ID'

					send_data(res)
				when 'unlock'
					# /unlock/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					user = parse_and_auth(uri[2..-1])
					if user.nil?
						send_data('Invalid parameters')
					else
						do_action(user, :unlock, id) do |result|
							send_data(result)
						end
					end
				when 'lock'
					# /lock/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					user = parse_and_auth(uri[2..-1])
					if user.nil?
						send_data('Invalid parameters')
					else
						do_action(user, :lock, id) do |result|
							send_data(result)
						end
					end
				when 'pop'
					# /pop/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					user = parse_and_auth(uri[2..-1])
					if user.nil?
						send_data('Invalid parameters')
					else
						do_action(user, :pop, id) do |result|
							send_data(result)
						end
					end
				when 'set_code'

				when 'add_to_access_list'

				when 'remove_from_access_list'

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
