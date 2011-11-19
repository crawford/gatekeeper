Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require '../lib/misc_helpers'
require 'sinatra'
require 'socket'
require 'yaml'
require 'redis'
require 'uuid'

add_to_loadpath("../lib", "../models")

require 'db'
require 'ldap'
require 'user'

class Main < Sinatra::Base
	FETCH_LOG = '
		SELECT users.uuid, types.name as type, actions.name as action, events.datetime
		FROM users, types, actions, events
		WHERE action_did = %d AND
		      user_id = users.id AND
		      type_id = types.id AND
		      action_id = actions.id
		ORDER BY events.datetime DESC
	'.freeze
	FETCH_DOOR_NAME = '
		SELECT name
		FROM doors
		WHERE id = %d
	'.freeze

	KEY_EXPIRE_TIME = 900.freeze # 15 minutes
	LOGIN_KEY = 'WEBAUTH_USER'

	before do
		db_config    = keys_to_symbols(YAML.load_file('config/database.yml')).freeze
		ldap_config  = keys_to_symbols(YAML.load_file('config/ldap.yml')).freeze
		redis_config = keys_to_symbols(YAML.load_file('config/redis.yml')).freeze

		Gatekeeper::DB.config = db_config
		Gatekeeper::Ldap.config = ldap_config

		begin
			@redis = Redis.new(redis_config)
			@redis.auth(redis_config[:password])
		rescue => e
			@last_error = e
		end

		@uuid = UUID.new
	end

	get '/' do
		return @last_error.to_s if @last_error

		hostname = Socket.gethostbyname(Socket.gethostname).first
		#TODO - Look this up
		wsport = 8080

		login = ENV[LOGIN_KEY]
		unless login
			return 'How in the holy hell did you get here?'
		end

		# Grab or generate the users secret key so they auth over websockets
		if @redis.exists(login)
			key = @redis.get(login)
		else
			key = @uuid.generate
			@redis.set(login, key)
			@redis.set(key, login)
		end

		# Push back the expiration time for the key
		@redis.expire(login, KEY_EXPIRE_TIME)
		@redis.expire(key, KEY_EXPIRE_TIME)

		erb :index, :locals => {:hostname => hostname, :wsport => wsport, :key => key}
	end

	get '/log/:door' do
		begin
			db   = Gatekeeper::DB.new
			ldap = Gatekeeper::Ldap.new

			dID = params[:door].to_i

			door_name = db.fetch(:name, FETCH_DOOR_NAME, dID)
			redirect '/' unless door_name

			user_cache = Hash.new
			log = db.query(FETCH_LOG, dID).collect do |entry|
				#TODO: This could be faster (one large query)
				if user_cache.has_key?(entry[:uuid])
					user = user_cache[entry[:uuid]]
				else
					user   = ldap.info_for_uuid(entry[:uuid])
					user ||= {:name => entry[:uuid]}

					user_cache[entry[:uuid]] = user
				end

				{:name => user[:name],
				 :type => entry[:type],
				 :action => entry[:action],
				 :datetime => entry[:datetime]
				}
			end
			log.compact!

			erb :log, :locals => {:log => log, :door => door_name}
		rescue => e
			return e.to_s
		end
	end

	not_found do
		redirect '/'
	end
end
