require 'eventmachine'
require 'fiber'

class MessageProcess < Fiber
	CANCELLED = 0.freeze
	TIMEDOUT  = 1.freeze

	attr_accessor :callback
	attr_accessor :cleanup

	def initialize(&blk)
		if block_given?
			super(&blk)
		else
			super do
			end
		end
		start_timer
	end

	def resume(*args)
		result = super(*args)
		if alive?
			start_timer
		else
			@timer.cancel
			@callback.call(result) if @callback
			@cleanup.call if @cleanup
		end
	end

	def cancel
		@timer.cancel
		@callback.call(CANCELLED) if @callback
		@cleanup.call if @cleanup
	end

	private

	def start_timer
		@timer.cancel if @timer
		@timer = EM::Timer.new(5) do
			@callback.call(TIMEDOUT) if @callback
			@cleanup.call if @cleanup
		end
	end
end
