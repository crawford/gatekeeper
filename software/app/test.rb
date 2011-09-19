require 'mysql2'

Dir.chdir(File.dirname(__FILE__))
$LOAD_PATH.unshift(".")

require 'lib/message_process'
require 'lib/hardware_interface'
require 'lib/zigbee_interface'
require 'lib/ldap'

EM.run do

	db = Mysql2::Client.new({:database=>'gatekeeper', :username=>'api', :password=>'123'})
	h = Gatekeeper::HardwareInterface.instance
	h.setup(db)

	callback = Proc.new do |result|
		puts "Callback #{result}"
	end

	h.query(2, callback)
	h.remove_from_al(2, [1], callback)

end
