require 'sinatra'
require 'mysql2'
require 'socket'

class Test < Sinatra::Base
	FETCH_LOG = '
		SELECT users.uuid, types.name as type, actions.name as action, events.datetime
		FROM users, types, actions, events
		WHERE action_did = %d &&
			  user_id = users.id &&
			  type_id = types.id &&
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
		db = Mysql2::Client.new({:username => 'api', :password => '123', :database => 'gatekeeper', :host => 'localhost'})
		door = db.query(FETCH_DOOR_NAME % params[:door].to_i).first['name']
		log = db.query(FETCH_LOG % params[:door].to_i)

		erb :log, :locals => {:log => log, :door => door}
	end

	not_found do
		redirect '/'
	end
end
