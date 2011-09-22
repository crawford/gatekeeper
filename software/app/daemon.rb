#! /usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require '../lib/misc_helpers'
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'daemons'

add_to_loadpath("config", "servers", "../lib", "../models")

require 'http_server'
require 'socket_server'
require 'web_socket_server'
require 'hardware_interface'
require 'ethernet_interface'
require 'db'

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
			Gatekeeper::DB.config = database
			Gatekeeper::Ldap.config = ldap

			zigbee = nil
			EM.connect(servers[:zigzag][:host],
			           servers[:zigzag][:port],
			           Gatekeeper::ZigbeeInterface) do |z|
				zigbee = z
			end

			api = Gatekeeper::ApiServer.instance
			api.zigbee = zigbee

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

			EM.start_server(servers[:ethernet][:interface],
			                servers[:ethernet][:port],
			                Gatekeeper::EthernetInterface,
			                servers[:websocket].merge(creds))
		end
	end
end

main
