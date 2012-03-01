module Gatekeeper
	class Exception < ::Exception
	end

	class DBConnectionError < Exception
		def initialize
			super 'Connection to database failed'
		end
	end
end
