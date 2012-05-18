Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require '../lib/misc_helpers'
require 'sinatra'
require 'socket'
require 'yaml'
require 'redis'
require 'uuid'
require 'erubis'

set :erubis, :escape_html => true

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
		      action_id = actions.id AND
		      DATE_ADD(events.datetime, INTERVAL 1 WEEK) > NOW()
		ORDER BY events.datetime DESC
	'.freeze
	FETCH_ACTIVE_RULES = '
		SELECT users.uuid, start_date, end_date
		FROM users, denials
		WHERE door_id = %d AND
		      user_id = users.id AND
		      end_date >= NOW()
		ORDER BY end_date ASC
	'.freeze
	FETCH_DOOR_NAME = '
		SELECT name
		FROM doors
		WHERE id = %d
	'.freeze
	INSERT_RULE = '
		INSERT INTO denials
		(user_id, door_id, start_date, end_date) VALUES (%d, %d, NOW(), DATE_ADD(NOW(), INTERVAL %d DAY))
	'.freeze
	FETCH_ID_FOR_UUID = '
		SELECT id
		FROM users
		WHERE uuid = "%s"
	'.freeze

	KEY_EXPIRE_TIME = 900.freeze # 15 minutes
	LOGIN_KEY = 'WEBAUTH_USER'

	before do
		begin
			db_config    = keys_to_symbols(YAML.load_file('config/database.yml')).freeze
			ldap_config  = keys_to_symbols(YAML.load_file('config/ldap.yml')).freeze
			redis_config = keys_to_symbols(YAML.load_file('config/redis.yml')).freeze

			Gatekeeper::DB.config = db_config
			Gatekeeper::Ldap.config = ldap_config

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

		login = request.env[LOGIN_KEY]
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

		erubis :index, :locals => {:hostname => hostname, :wsport => wsport, :key => key}
	end

	get '/info/:door' do
		begin
			login = request.env[LOGIN_KEY]
			db    = Gatekeeper::DB.new
			ldap  = Gatekeeper::Ldap.new

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

				{:name     => user[:name],
				 :type     => entry[:type],
				 :action   => entry[:action],
				 :datetime => entry[:datetime]}
			end
			log.compact!

			rules = db.query(FETCH_ACTIVE_RULES, dID).collect do |entry|
				#TODO: This could be faster (one large query)
				if user_cache.has_key?(entry[:uuid])
					user = user_cache[entry[:uuid]]
				else
					user   = ldap.info_for_uuid(entry[:uuid])
					user ||= {:name => entry[:uuid]}

					user_cache[entry[:uuid]] = user
				end

				{:name      => user[:name],
				 :startdate => entry[:start_date],
				 :enddate   => entry[:end_date]}
			end
			rules.compact!

			user  = ldap.info_for_username(login)

			erubis :info, :locals => {:door => door_name, :log => log, :rules => rules, :admin => user[:admin]}
		rescue => e
			return e.backtrace.join('<br />')
		end
	end

	post '/info/:door' do
		begin
			db    = Gatekeeper::DB.new
			ldap  = Gatekeeper::Ldap.new

			login    = request.env[LOGIN_KEY]
			dID      = params[:door].to_i
			username = params[:username]
			duration = params[:time]
			user     = ldap.info_for_username(username)
			admin    = ldap.info_for_username(login)

			redirect "/info/#{dID}", 303 unless dID and user and duration and admin[:admin]

			id = db.fetch(:id, FETCH_ID_FOR_UUID, user[:uuid].to_s)
			redirect "/info/#{dID}", 303 unless id

			db.query(INSERT_RULE, id, dID, duration)

			redirect "/info/#{dID}", 303
		rescue => e
			return e.backtrace.join('<br />')
		end
	end

	not_found do
		redirect '/'
	end
end
