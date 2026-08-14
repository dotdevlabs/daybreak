require "singleton"

class AgentPushRegistry
  include Singleton

  def initialize
    @streams = Hash.new { |h, k| h[k] = [] }
    @mutex = Mutex.new
  end

  def register(account_id, stream)
    @mutex.synchronize { @streams[account_id] << stream }
  end

  def unregister(account_id, stream)
    @mutex.synchronize { @streams[account_id].delete(stream) }
  end

  def broadcast_to(account_id, event_json)
    active = @mutex.synchronize { @streams[account_id].dup }
    active.each { |s| s.write(event_json) rescue nil }
    active.any?
  end
end
