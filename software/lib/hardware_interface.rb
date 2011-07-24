module Gatekeeper
	class HardwareInterface
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
	end
end
