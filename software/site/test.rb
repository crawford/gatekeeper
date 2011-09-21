Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require '../lib/misc_helpers'
require 'sinatra'
require 'mysql2'
require 'socket'
require 'yaml'

add_to_loadpath("../lib", "../models")

require 'ldap'
require 'user'

class Test < Sinatra::Base
	@database = keys_to_symbols(YAML.load_file('config/database.yml')).freeze
	@ldap     = keys_to_symbols(YAML.load_file('config/ldap.yml')).freeze

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
		SELECT name, message_address
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
		db = Mysql2::Client.new(@database)
		ldap = Gatekeeper::Ldap.new(@ldap)

		door = db.query(FETCH_DOOR_NAME % params[:door].to_i).first
		log = db.query(FETCH_LOG % door['message_address'].to_i).collect do |entry|
			user = ldap.info_for_uuid(entry['uuid'])
			{:name => user[:name],
			 :type => entry['type'],
			 :action => entry['action'],
			 :datetime => entry['datetime']
			}
		end

		erb :log, :locals => {:log => log, :door => door['name']}
	end

	not_found do
		redirect '/'
	end
end
