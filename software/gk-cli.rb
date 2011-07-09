#! /usr/bin/env ruby

$LOAD_PATH.unshift(Dir.pwd)

require "lib/misc_helpers"
require "socket"
require "yaml"

COMMANDS = ['stop']

def main
	if ARGV.length != 1 or not COMMANDS.include?(ARGV[0])
		puts "Usage: #{__FILE__} command"
		puts " Commands:"
		COMMANDS.each { |c| puts "  #{c}" }
		exit
	end

	begin
		server = keys_to_symbols(YAML.load_file("config/servers.yml"))[:control]

		TCPSocket.open(server[:host], server[:port]) do |socket|
			socket.print("stop")
		end

		puts "Server stopped"
	rescue Errno::ECONNREFUSED
		puts "Could not connect to server"
	rescue NoMethodError, Errno::ENOENT
		puts "Error loading configuration"
	end
end

main
