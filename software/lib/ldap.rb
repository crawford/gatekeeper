require 'net-ldap'
require 'user'

LDAP_USER_BASE = 'ou=Users,dc=csh,dc=rit,dc=edu'.freeze

class Ldap
	def initialize(config)
		host     = config[:host]
		port     = config[:port]
		username = config[:username]
		password = config[:password]

		@ldap = Net::LDAP.new({
			:host => host,
			:port => port,
			:auth => {
				:method   => :simple,
				:username => username,
				:password => password
			},
			:encryption => :simple_tls
		})

		unless @ldap.bind
			@ldap = nil
			fail 'Could not connect to ldap'
		end
	end

	def info_for_ibutton(ibutton)
		filter = Net::LDAP::Filter.eq('ibutton', ibutton)
		perform_info_search(filter)
	end

	def info_for_username(username)
		filter = Net::LDAP::Filter.eq('uid', username)
		perform_info_search(filter)
	end

	private

	def perform_info_search(filter)
		#TODO: Add admin
		result = @ldap.search({
			:base       => LDAP_USER_BASE,
			:filter     => filter,
			:attributes => ['ibutton', 'entryUUID', 'cn'],
			:size       => 1
		}).first

		return nil unless result

		ibutton = result[:ibutton].first
		uuid    = result[:entryUUID].first
		cn     = result[:cn].first

		{:ibutton => ibutton, :uuid => uuid, :name => cn}
	end
end
