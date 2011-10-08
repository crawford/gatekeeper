require 'eventmachine'
require 'fiber'

class MessageProcess < Fiber
	attr_accessor :callback
	attr_accessor :cleanup

	SUCCESS  = 'S'.freeze
	LOCKED   = 'L'.freeze
	UNLOCKED = 'U'.freeze

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
			dID    = payload[0]
			result = payload[1]

			success = (payload == SUCCESS or payload == LOCKED or payload == UNLOCKED)
			error_type = if success then nil else :failure end
			error = if success then nil else 'Operation failed' end

			@timer.cancel
			@callback.call({
				:success => success,
				:error_type => error_type,
				:error => error
			}) if @callback
			@cleanup.call if @cleanup
		end
	end

	def cancel
		@timer.cancel
		@callback.call(
			{:success => false,
			 :error_type => :cancelled,
			 :error => 'Operation cancelled'
			}) if @callback
		@cleanup.call if @cleanup
	end

	def fail
		@timer.cancel
		@callback.call(
			{:success => false,
			 :error_type => :failure,
			 :error => 'Operation failed'
			}) if @callback
	end

	private

	def start_timer
		@timer.cancel if @timer
		@timer = EM::Timer.new(5) do
			@callback.call(
				{:success => false,
				 :error_type => :timeout,
				 :error => 'Operation timed out'
				}) if @callback
			@cleanup.call if @cleanup
		end
	end
end
