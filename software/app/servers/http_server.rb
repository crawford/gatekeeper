#TODO: super fast hack code
#TODO: ibutton authentication no longer supported

require 'http_parser'
require 'api_server'

module Gatekeeper
	class HttpServer < EM::Connection
		INVALID_CREDS = {:success    => false,
		                 :error_type => :login,
		                 :error      => 'Invalid username or password',
		                 :response   => nil
		                }.freeze
		INVALID_COMMAND = {:success    => false,
		                   :error_type => :command,
		                   :error      => 'Invalid command',
		                   :response   => nil
		                  }.freeze
		INVALID_DOOR = {:success    => false,
		                :error_type => :command,
		                :error      => 'Invalid or missing ID',
		                :response   => nil
		               }.freeze
		DOOR_STATE = {:success    => true,
		              :error_type => nil,
		              :error      => nil,
		              :response   => nil
		             }.freeze

		def initialize(config)
			@parser = Http::Parser.new
			@parser.on_headers_complete = proc { :stop }
		end

		def receive_data(data)
			unless @last_error
				begin
					offset = @parser << data
					post = data[offset..-1].split('&')

					post = post.inject({}) do |hash, data|
						args = data.strip.split('=')
						hash[args[0].to_sym] = args[1]
						hash
					end

					parse_request(@parser.request_url, post)
				rescue => e
					puts 'Exception occured: ' << e.to_s
					close_connection
				end
			else
				puts 'Exception occured: ' << @last_error.to_s
				close_connection
			end
		end

		def parse_request(uri, post)
			uri = uri[1..-1].split('/')
			user = auth_from_post(post)

			# Allow cross domain requests
			send_data("HTTP/1.1 200 OK\r\n")
			send_data("Content-Type:application/json\r\n")
			send_data("Access-Control-Allow-Origin:*\r\n\r\n")

			case uri[0]
				when 'all_doors'
					# /all_doors
					send_data(DOOR_STATE.merge(:response => ApiServer.instance.fetch_all_doors(user)).to_json)
					close_connection_after_writing
				when 'door_state'
					# /door_state/(door id)
					id = uri[1].to_i
					doors = ApiServer.instance.fetch_all_doors(user)
					doors.each do |door|
						if door[:id] == id
							send_data(DOOR_STATE.merge(:response => door).to_json)
							close_connection_after_writing
							break
						end
					end
					send_data(INVALID_DOOR)
					close_connection_after_writing

				when 'unlock'
					# /unlock/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					if user
						ApiServer.instance.do_action(user, :unlock, id) do |result|
							send_data(result.to_json)
							close_connection_after_writing
						end
					else
						send_data(INVALID_CREDS.to_json)
						close_connection_after_writing
					end
				when 'lock'
					# /lock/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					if user
						ApiServer.instance.do_action(user, :lock, id) do |result|
							send_data(result.to_json)
							close_connection_after_writing
						end
					else
						send_data(INVALID_CREDS.to_json)
						close_connection_after_writing
					end
				when 'pop'
					# /pop/(door id)
					# POST username: (username)
					# POST password: (password)
					id = uri[1].to_i
					if user
						ApiServer.instance.do_action(user, :pop, id) do |result|
							send_data(result.to_json)
							close_connection_after_writing
						end
					else
						send_data(INVALID_CREDS.to_json)
						close_connection_after_writing
					end
				when 'set_code'

				when 'add_to_access_list'

				when 'remove_from_access_list'

				when 'favicon'
				else
					send_data(INVALID_COMMAND.to_json)
					close_connection_after_writing
			end
		end

		private

		def auth_from_post(post)
			return nil unless post

			username = post[:username]
			password = post[:password]
			userkey  = post[:userkey]

			return ApiServer.instance.authenticate_user(username, password) if username and password
			return ApiServer.instance.authenticate_user(userkey) if userkey
		end
	end
end
