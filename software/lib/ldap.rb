require 'net-ldap'
require 'user'

LDAP_USER_BASE = 'ou=Users,dc=csh,dc=rit,dc=edu'.freeze

class Ldap
	def initialize(config)
		host     = config.delete(:host)
		port     = config.delete(:port)
		username = config.delete(:username)
		password = config.delete(:password)

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

	def info_for_username(username)
		filter = Net::LDAP::Filter.eq('uid', username)

		result = @ldap.search({
			:base       => LDAP_USER_BASE,
			:filter     => filter,
			:attributes => ['ibutton', 'entryUUID'],
			:size       => 1
		}).first

		return nil unless result

		ibutton = result[:ibutton].first
		uuid    = result[:entryUUID].first

		{:ibutton => ibutton, :uuid => uuid}
	end
end
