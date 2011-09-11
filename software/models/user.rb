module Gatekeeper
	class User
		attr_reader :uuid
		attr_reader :admin
		attr_reader :name
		attr_reader :ibutton
		attr_reader :id

		def initialize(config)
			@uuid    = config[:uuid]
			@admin   = config[:admin]
			@name    = config[:name]
			@ibutton = config[:ibutton]
			@id      = config[:id]
		end
	end
end
