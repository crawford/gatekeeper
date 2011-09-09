module Gatekeeper
	class User
		attr_reader :uuid
		attr_reader :admin
		attr_reader :name
		attr_reader :ibutton

		def initialize(uuid, admin, name, ibutton)
			@uuid = uuid
			@admin = admin
			@name = name
			@ibutton = ibutton
		end
	end
end
