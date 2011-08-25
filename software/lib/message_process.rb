require 'eventmachine'
require 'fiber'

class MessageProcess < Fiber
	attr_accessor :callback
	attr_accessor :cleanup

	SUCCESS = 'S'.freeze

	def initialize(&blk)
		if block_given?
			super(&blk)
		else
			super do
			end
		end
		start_timer
	end

	def resume(payload)
		result = super(payload)
		if alive?
			start_timer
		else
			success = (payload == SUCCESS)
			error = if success then nil else 'Operation failed' end
			@timer.cancel
			@callback.call({:success => success, :error => error}) if @callback
			@cleanup.call if @cleanup
		end
	end

	def cancel
		@timer.cancel
		@callback.call({:success => false, :error => 'Operation cancelled'}) if @callback
		@cleanup.call if @cleanup
	end

	private

	def start_timer
		@timer.cancel if @timer
		@timer = EM::Timer.new(5) do
			@callback.call({:success => false, :error => 'Operation timed out'}) if @callback
			@cleanup.call if @cleanup
		end
	end
end
