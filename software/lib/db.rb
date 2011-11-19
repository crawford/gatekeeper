require 'mysql2'

module Gatekeeper
	class DB < Mysql2::Client
		@@config = nil

		attr_accessor :config

		def self.config=(config)
			@@config = config
		end

		def initialize(*config)
			@@config = config.first unless config.empty?
			fail 'Database must be configured' unless @@config

			super(@@config)
			query_options.merge!(:symbolize_keys => true)
		end


		# Executes the query with substituted args and returns the specified
		# attribute from the first result or nil if there are no results.

		def fetch(attribute, query, *args)
			results = query(query, *args)
			return if results.size == 0

			out = []
			results.each do |result|
				out << result[attribute]
			end
			return out.first if out.size == 1
			out
		end


		# Substitutes the args into the query and executes it.

		def query(query, *args)
			begin
				super(query % args)
			rescue
				reconnect!
				retry
			end
		end
	end
end
