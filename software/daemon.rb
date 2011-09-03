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


def main
	servers   = keys_to_symbols(YAML.load_file('config/servers.yml'))
	databases = keys_to_symbols(YAML.load_file('config/database.yml'))

	EM.kqueue
	EM.epoll

	Daemons.run_proc('gatekeeper', :dir_mode => :script, :multiple => false, :log_output => true) do
		EM.run do
			EM.start_server(servers[:socket][:interface],
			                servers[:socket][:port],
			                Gatekeeper::SocketServer,
			                servers[:socket].merge(:database => databases))

			EM.start_server(servers[:control][:interface],
			                servers[:control][:port],
			                Gatekeeper::ControlServer,
			                servers[:control].merge(:database => databases))

			EM.start_server(servers[:websocket][:interface],
			                servers[:websocket][:port],
			                Gatekeeper::WebSocketServer,
			                servers[:websocket].merge(:database => databases))

			EM.start_server(servers[:http][:interface],
			                servers[:http][:port],
			                Gatekeeper::HttpServer,
			                servers[:http].merge(:database => databases))

			EM.connect(servers[:zigzag][:host],
			           servers[:zigzag][:port],
			           ZigzagClient,
			           servers[:zigzag])
		end
	end
end

main
