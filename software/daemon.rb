#! /usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require 'lib/misc_helpers'
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'daemons'

add_to_loadpath("config", "servers", "lib", "models")

require 'control_server'
require 'http_server'
require 'socket_server'
require 'web_socket_server'
require 'zigzag_client'
require 'hardware_interface'


def main
	servers   = keys_to_symbols(YAML.load_file('config/servers.yml')).freeze
	databases = keys_to_symbols(YAML.load_file('config/database.yml')).freeze

	EM.kqueue
	EM.epoll

	Daemons.run_proc('gatekeeper', :dir_mode => :script, :multiple => false, :log_output => true) do
		EM.run do
			db = Mysql2::Client.new(databases)
			zigbee = nil

			EM.connect(servers[:zigzag][:host],
			           servers[:zigzag][:port],
			           Gatekeeper::ZigbeeInterface) do |z|
				zigbee = z
			end

			hardware = Gatekeeper::HardwareInterface.instance
			hardware.setup(db, zigbee)

			EM.start_server(servers[:socket][:interface],
			                servers[:socket][:port],
			                Gatekeeper::SocketServer,
			                servers[:socket].merge(:database => databases))

			EM.start_server(servers[:control][:interface],
			                servers[:control][:port],
			                Gatekeeper::ControlServer,
			                servers[:control].merge(:database => databases))

			EM.start_server(servers[:http][:interface],
			                servers[:http][:port],
			                Gatekeeper::HttpServer,
			                servers[:http].merge(:database => databases))

			EM.start_server(servers[:websocket][:interface],
			                servers[:websocket][:port],
			                Gatekeeper::WebSocketServer,
			                servers[:websocket].merge(:database => databases))
		end
	end
end

main
