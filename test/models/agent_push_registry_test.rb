require "test_helper"

class AgentPushRegistryTest < ActiveSupport::TestCase
  ACCOUNT_A = 1
  ACCOUNT_B = 2

  def setup
    @registry = AgentPushRegistry.instance
    @registry.instance_variable_set(:@streams, Hash.new { |h, k| h[k] = [] })
  end

  test "broadcast_to returns false when no streams are registered for account" do
    assert_equal false, @registry.broadcast_to(ACCOUNT_A, '{"test":true}')
  end

  test "broadcast_to returns true and writes to registered streams for account" do
    written = []
    stream = Object.new
    stream.define_singleton_method(:write) { |json| written << json }

    @registry.register(ACCOUNT_A, stream)
    result = @registry.broadcast_to(ACCOUNT_A, '{"type":"test"}')

    assert_equal true, result
    assert_equal [ '{"type":"test"}' ], written
  end

  test "unregister removes stream so broadcast_to returns false" do
    stream = Object.new
    stream.define_singleton_method(:write) { |_| }

    @registry.register(ACCOUNT_A, stream)
    @registry.unregister(ACCOUNT_A, stream)

    assert_equal false, @registry.broadcast_to(ACCOUNT_A, '{"test":true}')
  end

  test "broadcast_to silences errors from broken streams and continues to healthy ones" do
    bad_stream = Object.new
    bad_stream.define_singleton_method(:write) { |_| raise IOError, "stream broken" }
    written = []
    good_stream = Object.new
    good_stream.define_singleton_method(:write) { |json| written << json }

    @registry.register(ACCOUNT_A, bad_stream)
    @registry.register(ACCOUNT_A, good_stream)

    assert_nothing_raised { @registry.broadcast_to(ACCOUNT_A, '{"test":true}') }
    assert_equal [ '{"test":true}' ], written
  end

  test "streams registered under account A are not delivered when broadcasting to account B" do
    written_a = []
    stream_a = Object.new
    stream_a.define_singleton_method(:write) { |json| written_a << json }

    @registry.register(ACCOUNT_A, stream_a)
    @registry.broadcast_to(ACCOUNT_B, '{"type":"test"}')

    assert_empty written_a, "account A stream should not receive account B broadcast"
  end

  test "concurrent register and unregister does not corrupt state" do
    streams = 10.times.map do
      s = Object.new
      s.define_singleton_method(:write) { |_| }
      s
    end

    threads = streams.map { |s| Thread.new { @registry.register(ACCOUNT_A, s) } }
    threads.each(&:join)
    assert_equal 10, @registry.instance_variable_get(:@streams)[ACCOUNT_A].size

    threads = streams.map { |s| Thread.new { @registry.unregister(ACCOUNT_A, s) } }
    threads.each(&:join)
    assert_equal 0, @registry.instance_variable_get(:@streams)[ACCOUNT_A].size
  end
end
