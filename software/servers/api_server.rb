require 'mysql2'
require 'json'
require 'user'
require 'hardware_interface'

module Gatekeeper
	module ApiServer
		include EM::Deferrable

		USER_ACTIONS =  [:pop, :unlock, :lock].freeze
		ADMIN_ACTIONS = [:add_rule, :remove_rule, :add_ibutton, :remove_ibutton].freeze

		FETCH_ALL_DOORS = '
			SELECT doors.id, doors.name
			FROM doors
		'.freeze
		CAN_USER_PERFORM_ACTION = '
			SELECT COUNT(*) AS count
			FROM denials
			WHERE (start_date <= NOW() OR start_date IS NULL) AND
			(end_date >= NOW() OR end_date IS NULL) AND
			user_id = %d AND door_id = %d
		'.freeze
		GET_ID_BY_VALUE = '
			SELECT id
			FROM %s
			WHERE name = "%s"
		'.freeze
		INSERT_VALUE = '
			INSERT INTO %s
			(name) VALUES ("%s")
		'.freeze
		LOG_EVENT = '
			INSERT INTO events
			(datetime, user_id, type_id, action_id, action_did, action_arg, service_id) VALUES (NOW(), %d, %d, %d, %d, "%s", %d)
		'.freeze


		# Open a connection to the Gatekeeper database and LDAP

		def initialize(config)
			begin
				@db = Mysql2::Client.new(config[:database])
				@ldap = Ldap.new(config[:ldap])
				@last_error = nil
				@hardware = HardwareInterface.instance
				@@states ||= nil
				unless @@states
					doors = fetch_all_doors
					doors.each do |door|
						#TODO: update the states here
						p door
					end
				end
			# TODO: Rescue LDAP connection errors
			rescue Mysql2::Error => e
				p e
				@last_error = e
			end
		end


		# Fetch a list of all doors from the database.
		# Returns the following in an array of hashes:
		#  - Door Name
		#  - Door ID
		#  - Door State

		def fetch_all_doors
			query(FETCH_ALL_DOORS).each
		end


		# Authenticates a user by either username and password or ibutton id.
		# If successful, this returns an object representing the user.
		# If unsuccessful, this returns nil and the event is logged.

		def authenticate_user(*args)
			case args.size
				# (iButtonID)
				when 1
					info = @ldap.info_for_ibutton(args[0])
					return User.new(info[:uuid], false, info[:name])
				when 2
					#TODO: actually lookup the user from LDAP
					return User.new(2, true)
				else
					raise ArgumentError.new('Invalid number of arguments (expecting 1 or 2)')
			end
		end


		# Check to see if the user can perform the specified action,
		# perform the action (if allowed), and log it to the database

		def do_action(user, action, dID, arg = nil, &block)
			raise ArgumentError.new('Invalid user') if user.nil?
			if can_user_do?(user, action, dID)
				callback = Proc.new do |result|
					log_action(user, :success, action, dID, arg)
					yield result
				end

				case action
					when :pop
						@hardware.pop(dID, callback)
					when :unlock
						@hardware.unlock(dID, callback)
					when :lock
						@hardware.lock(dID, callback)
					when :add_ibutton
						@hardware.add_to_al(dID, arg, callback)
					when :remove_ibutton
						@hardware.remove_from_al(dID, arg, callback)
				end
			else
				log_action(user.uuid, :denial, action, dID, arg)
				yield({:success => false, :error => 'User is not allowed to perform specified action'})
			end
		end


		# Fetch the state of a single door (given by the door id).

		def fetch_door_state(id, callback)
			call = Proc.new do |state|
				@@states[id] = state
				callback(state)
			end
			@hardware.query(id, call)
		end

		private


		# Checks to see if the current user is allowed to
		# perform the specified action.
		# Returns a boolean indicating whether or not the user is allowed.

		def can_user_do?(user, action, dID)
			if USER_ACTIONS.include?(action)
				raise ArgumentError.new('dID must be a fixnum') unless dID.is_a?(Fixnum)
				return fetch(:count, CAN_USER_PERFORM_ACTION, user.uuid, dID) == 0
			elsif ADMIN_ACTIONS.include?(action)
				return user.admin
			else
				raise ArgumentError.new("Invalid action (#{action})")
			end
		end


		# Logs the action by the user to the database

		def log_action(user, type, action, dID, arg = nil)
			arg ||= ''
			type_id = get_id_or_create(:types, type)
			action_id = get_id_or_create(:actions, action)
			service_id = get_id_or_create(:services, self.class.to_s.downcase)

			query(LOG_EVENT, user.uuid, type_id, action_id, dID, arg, service_id)
		end


		# Fetches the id of the value from the specified table.
		# If the value doesn't exist, create it and return the id.

		def get_id_or_create(table, value)
			result = fetch(:id, GET_ID_BY_VALUE, table, value)
			return result unless result.nil?

			query(INSERT_VALUE, table, value)
			fetch(:id, GET_ID_BY_VALUE, table, value)
		end


		# Executes the query with substituted args and returns the specified
		# attribute from the first result or nil if there are no results.

		def fetch(attribute, query, *args)
			results = query(query, *args)
			return if results.size == 0

			out = []
			results.each(:symbolize_keys => true) do |result|
				out << result[attribute]
			end
			return out.first if out.size == 1
			out
		end


		# Substitutes the args into the query and executes it.

		def query(query, *args)
			@db.query(query % args)
		end
	end
end
