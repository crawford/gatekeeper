require 'net-ldap'
require 'user'

LDAP_USER_BASE   = 'ou=Users,dc=csh,dc=rit,dc=edu'.freeze
LDAP_GROUPS_BASE = 'ou=Groups,dc=csh,dc=rit,dc=edu'.freeze
LDAP_GROUP_CN    = 'keymaster'.freeze

module Gatekeeper
	class Ldap
		include Net

		@@config = nil

		def self.config=(config)
			@@config = config
		end

		def initialize(*config)
			@@config = config.first unless config.empty?
			fail 'LDAP must be configured' unless @@config

			@host     = @@config[:host]
			@port     = @@config[:port]
			username = @@config[:username]
			password = @@config[:password]

			@ldap = LDAP.new({
				:host => @host,
				:port => @port,
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
			filter = LDAP::Filter.eq('ibutton', ibutton)
			perform_info_search(filter)
		end

		def info_for_username(username)
			filter = LDAP::Filter.eq('uid', username)
			perform_info_search(filter)
		end

		def info_for_uuid(uuid)
			filter = LDAP::Filter.eq('entryUUID', uuid)
			perform_info_search(filter)
		end

		def validate_user_credentials(username, password)
			conn = LDAP.new({
				:host => @host,
				:port => @port,
				:auth => {
					:method   => :simple,
					:username => "uid=#{username}, #{LDAP_USER_BASE}",
					:password => password
				},
				:encryption => :simple_tls
			})
			p conn.get_operation_result
			conn.bind
		end

		private

		def perform_info_search(filter)
			result = @ldap.search({
				:base       => LDAP_USER_BASE,
				:filter     => filter,
				:attributes => ['ibutton', 'entryUUID', 'cn', 'dn'],
				:size       => 1
			}).first

			return nil unless result

			ibutton = result[:ibutton].first
			uuid    = result[:entryUUID].first
			cn     = result[:cn].first
			dn     = result[:dn].first

			result = @ldap.search({
				:base       => LDAP_GROUPS_BASE,
				:filter     => LDAP::Filter.join(LDAP::Filter.eq('objectClass', 'groupOfNames'), LDAP::Filter.eq('cn', LDAP_GROUP_CN)),
				:attributes => ['member'],
				:size       => 1
			}).first

			admin = result[:member].include?(dn)

			{:ibutton => ibutton, :uuid => uuid, :name => cn, :admin => admin}
		end
	end
end
