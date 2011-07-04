#! /usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'control_server'
require 'http_server'
require 'socket_server'
require 'web_socket_server'

def main
	config = keys_to_symbols(YAML.load_file('config.yml'))

	EM.kqueue
	EM.epoll

	servers = config[:servers]
	EM.run do
	EM.start_server(servers[:socket][:interface],
	                servers[:socket][:port],
	                Gatekeeper::SocketServer,
	                servers[:socket].merge(:database => config[:database]))

	EM.start_server(servers[:control][:interface],
	                servers[:control][:port],
	                Gatekeeper::ControlServer,
	                servers[:control].merge(:database => config[:database]))

	EM.start_server(servers[:websocket][:interface],
	                servers[:websocket][:port],
	                Gatekeeper::WebSocketServer,
	                servers[:websocket].merge(:database => config[:database]))

	EM.start_server(servers[:http][:interface],
	                servers[:http][:port],
	                Gatekeeper::HttpServer,
	                servers[:http].merge(:database => config[:database]))
	end
end

def keys_to_symbols(value)
	return value if not value.is_a?(Hash)
	hash = value.inject({}) do |hash,(k,v)|
		hash[k.to_sym] = keys_to_symbols(v)
		hash
	end
end

main
