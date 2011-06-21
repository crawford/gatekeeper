#! /usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'eventmachine'
require 'api_server'
require 'api_server_controller'
require 'yaml'

CONFIG = YAML.load_file('config.yml')

EM.kqueue
EM.epoll

EM.run do
	EM.start_server(CONFIG['server']['service_interface'],
					CONFIG['server']['service_port'],
					ApiServer)

	EM.start_server(CONFIG['server']['control_interface'],
					CONFIG['server']['control_port'],
					ApiServerController)
end
