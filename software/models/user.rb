module Gatekeeper
	class User
		attr_reader :id
		attr_reader :admin

		def initialize(id, admin)
			@id = id
			@admin = admin
		end
	end
end
