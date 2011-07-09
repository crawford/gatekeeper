module Gatekeeper
	class HardwareInterface
		def query(dID, callback = nil)
		def lock(dID, callback = nil)
		def unlock(dID, callback = nil)
		def clear_al(dID, callback = nil)
		def pop(dID, callback = nil)
		def add_to_al(dID, iButtons, callback = nil)
		def remove_from_al(dID, iButtons, callback = nil)
		def show_status(dID, status, callback = nil)
	end
end
