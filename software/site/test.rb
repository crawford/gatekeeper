Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require '../lib/misc_helpers'
require 'sinatra'
require 'socket'
require 'yaml'

add_to_loadpath("../lib", "../models")

require 'db'
require 'ldap'
require 'user'

class Test < Sinatra::Base
	def initialize
		db_config   = keys_to_symbols(YAML.load_file('config/database.yml')).freeze
		ldap_config = keys_to_symbols(YAML.load_file('config/ldap.yml')).freeze

		Gatekeeper::DB.config = db_config
		Gatekeeper::Ldap.config = ldap_config
		super
	end

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

	get '/' do
		hostname = Socket.gethostbyname(Socket.gethostname).first
		#TODO - Look this up
		wsport = 8080
		erb :index, :locals => {:hostname => hostname, :wsport => wsport}
	end

	get '/log/:door' do
		db   = Gatekeeper::DB.new
		ldap = Gatekeeper::Ldap.new
		dID  = params[:door].to_i

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
	end

	not_found do
		redirect '/'
	end
end
