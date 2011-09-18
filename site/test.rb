require 'sinatra'
require 'mysql2'
require 'socket'

#TODO - this is just disgusting...
$LOAD_PATH << '../software/lib'
$LOAD_PATH << '../software/models'

require 'ldap'
require 'user'

class Test < Sinatra::Base
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
		db = Mysql2::Client.new({:username => 'api', :password => '123', :database => 'gatekeeper', :host => 'localhost'})
		ldap = Gatekeeper::Ldap.new({
			:username => 'cn=gatekeeper,ou=Apps,dc=csh,dc=rit,dc=edu',
			:password => 'White298^down',
			:host => 'ldap.csh.rit.edu',
			:port => '636'
		})

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
