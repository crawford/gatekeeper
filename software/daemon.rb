#! /usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require 'lib/misc_helpers'
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'daemons'

add_to_loadpath("config", "servers", "lib", "models")

require 'http_server'
require 'socket_server'
require 'web_socket_server'
require 'hardware_interface'

def main
	servers   = keys_to_symbols(YAML.load_file('config/servers.yml')).freeze
	database  = keys_to_symbols(YAML.load_file('config/database.yml')).freeze
	ldap      = keys_to_symbols(YAML.load_file('config/ldap.yml')).freeze
	creds     = {:database => database, :ldap => ldap}.freeze

	EM.kqueue
	EM.epoll

	Daemons.run_proc('gatekeeper', :dir_mode => :script, :multiple => false, :log_output => true) do
		EM.run do
			# Setup the persistant connections
			db = Mysql2::Client.new(database)

			zigbee = nil
			EM.connect(servers[:zigzag][:host],
			           servers[:zigzag][:port],
			           Gatekeeper::ZigbeeInterface) do |z|
				zigbee = z
			end

			hardware = Gatekeeper::HardwareInterface.instance
			hardware.setup(db, zigbee)

			# Setup the worker connections
			EM.start_server(servers[:socket][:interface],
			                servers[:socket][:port],
			                Gatekeeper::SocketServer,
			                servers[:socket].merge(creds))

			EM.start_server(servers[:http][:interface],
			                servers[:http][:port],
			                Gatekeeper::HttpServer,
			                servers[:http].merge(creds))

			EM.start_server(servers[:websocket][:interface],
			                servers[:websocket][:port],
			                Gatekeeper::WebSocketServer,
			                servers[:websocket].merge(creds))
		end
	end
end

main
