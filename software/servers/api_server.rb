require 'mysql2'
require 'user'

module Gatekeeper
	module ApiServer
		include EM::Deferrable

		USER_ACTIONS =  [:pop, :unlock, :lock]
		ADMIN_ACTIONS = [:add_rule, :remove_rule, :add_ibutton, :remove_ibutton]

		STATE = 'state'
		COUNT = 'count'
		ID =    'id'

		FETCH_ALL_DOORS = '
			SELECT doors.id, doors.name, states.name AS state
			FROM doors, states
			WHERE doors.state_id = states.id
		'
		FETCH_DOOR_STATUS = '
			SELECT states.name AS state
			FROM doors, states
			WHERE doors.state_id = states.id AND doors.id = %d
		'
		CAN_USER_PERFORM_ACTION = '
			SELECT COUNT(*) AS count
			FROM denials
			WHERE (start_date <= NOW() OR start_date IS NULL) AND
			(end_date >= NOW() OR end_date IS NULL) AND
			user_id = %d AND door_id = %d
		'
		GET_ID_BY_VALUE = '
			SELECT id
			FROM %s
			WHERE name = "%s"
		'
		INSERT_VALUE = '
			INSERT INTO %s
			(name) VALUES ("%s")
		'
		LOG_EVENT = '
			INSERT INTO events
			(time, user_id, type_id, action_id, action_arg, service_id) VALUES (NOW(), %d, %d, %d, "%s", %d)
		'


		# Open a connection to the Gatekeeper database and LDAP

		def initialize(config)
			@db = Mysql2::Client.new(config[:database])
			@ldap = nil
		end


		# Fetch a list of all doors from the database.
		# Returns the following in an array of hashes:
		#  - Door Name
		#  - Door ID
		#  - Door State

		def fetch_all_doors
			query(FETCH_ALL_DOORS).each(:symbolize_keys => true)
		end


		# Fetch the state of a single door (given by the door id).
		# Returns the (symbolized) state of the door

		def fetch_door_state(id)
			result = fetch(STATE, FETCH_DOOR_STATUS, id)
			result.to_sym unless result.nil?
		end


		# Authenticates a user by either username and password or ibutton id.
		# If successful, this returns an object representing the user.
		# If unsuccessful, this returns nil and the event is logged.

		def authenticate_user(*args)
			case args.size
				# (iButtonID)
				when 1
					#TODO: actually lookup the user from LDAP
					return User.new(1, false)
				# (username, password)
				when 2
					#TODO: actually lookup the user from LDAP
					return User.new(2, true)
				else
					raise ArgumentError.new('Invalid number of arguments (expecting 1 or 2)')
			end
		end


		# Check to see if the user can perform the specified action,
		# perform the action (if allowed), and log it to the database

		def do_action(user, action, arg, &block)
			raise ArgumentError.new('Invalid user') if user.nil?
			unless can_user_do?(user, action, arg)
				log_action(user, :denial, action, arg)
				yield false
			end
			# TODO: do the action
			log_action(user, :success, action, arg)
			yield true
		end


		private


		# Checks to see if the current user is allowed to
		# perform the specified action.
		# Returns a boolean indicating whether or not the user is allowed.

		def can_user_do?(user, action, arg)
			if USER_ACTIONS.include?(action)
				raise ArgumentError.new('arg must be a fixnum') unless arg.is_a?(Fixnum)
				return fetch(COUNT, CAN_USER_PERFORM_ACTION, user.id, arg) == 0
			elsif ADMIN_ACTIONS.include?(action)
				return user.admin
			else
				raise ArgumentError.new("Invalid action (#{action})")
			end
		end


		# Logs the action by the user to the database

		def log_action(user, type, action, arg = nil)
			type_id = get_id_or_create(:types, type)
			action_id = get_id_or_create(:actions, action)
			service_id = get_id_or_create(:services, self.class.to_s.downcase)

			query(LOG_EVENT, user.id, type_id, action_id, arg, service_id)
		end


		# Fetches the id of the value from the specified table.
		# If the value doesn't exist, create it and return the id.

		def get_id_or_create(table, value)
			result = fetch(ID, GET_ID_BY_VALUE, table, value)
			return result unless result.nil?

			query(INSERT_VALUE, table, value)
			fetch(ID, GET_ID_BY_VALUE, table, value)
		end


		# Executes the query with substituted args and returns the specified
		# attribute from the first result or nil if there are no results.

		def fetch(attribute, query, *args)
			results = query(query, *args)
			return if results.size == 0
			results.first[attribute]
		end


		# Substitutes the args into the query and executes it.

		def query(query, *args)
			@db.query(query % args)
		end
	end
end
