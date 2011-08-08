require 'mysql2'

module Gatekeeper
	class HardwareInterface
		FETCH_INTERFACE_FROM_DID = '
			SELECT interfaces.name AS interface
			FROM doors, interfaces
			WHERE doors.interface_id = interfaces.id AND doors.id = %d
		'

		INTERFACE = 'interface'

		def initialize(db)
			@zigbee = ZigbeeInterface.new
			@ethernet = nil
			@db = db
		end

		def query(dID, callback = nil)
		end
		def lock(dID, callback = nil)
		end
		def unlock(dID, callback = nil)
		end
		def clear_al(dID, callback = nil)
		end
		def pop(dID, callback = nil)
		end
		def add_to_al(dID, iButtons, callback = nil)
		end
		def remove_from_al(dID, iButtons, callback = nil)
		end
		def show_status(dID, status, callback = nil)
		end

		private

		# Return the interface object associated with the specified dID

		def getInterfaceForDID(dID)
			case fetch(INTERFACE, FETCH_INTERFACE_FROM_DID, dID)
				when 'zigbee' then @zigbee
				when 'ethernet' then @ethernet
			end
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
