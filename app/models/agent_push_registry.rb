require "singleton"

class AgentPushRegistry
  include Singleton

  def initialize
    @streams = []
    @mutex = Mutex.new
  end

  def register(stream)
    @mutex.synchronize { @streams << stream }
  end

  def unregister(stream)
    @mutex.synchronize { @streams.delete(stream) }
  end

  # Returns true if at least one stream was written to.
  def broadcast(event_json)
    active = @mutex.synchronize { @streams.dup }
    active.each do |stream|
      stream.write(event_json) rescue nil
    end
    active.any?
  end
end
