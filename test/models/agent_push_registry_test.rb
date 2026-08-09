require "test_helper"

class AgentPushRegistryTest < ActiveSupport::TestCase
  def setup
    @registry = AgentPushRegistry.instance
    @registry.instance_variable_set(:@streams, [])  # reset between tests
  end

  test "broadcast returns false when no streams are registered" do
    assert_equal false, @registry.broadcast('{"test":true}')
  end

  test "broadcast returns true and writes to registered streams" do
    written = []
    stream = Object.new
    stream.define_singleton_method(:write) { |json| written << json }

    @registry.register(stream)
    result = @registry.broadcast('{"type":"test"}')

    assert_equal true, result
    assert_equal [ '{"type":"test"}' ], written
  end

  test "unregister removes stream so broadcast returns false" do
    stream = Object.new
    stream.define_singleton_method(:write) { |_| }

    @registry.register(stream)
    @registry.unregister(stream)

    assert_equal false, @registry.broadcast('{"test":true}')
  end

  test "broadcast silences errors from broken streams and continues to healthy ones" do
    bad_stream = Object.new
    bad_stream.define_singleton_method(:write) { |_| raise IOError, "stream broken" }
    written = []
    good_stream = Object.new
    good_stream.define_singleton_method(:write) { |json| written << json }

    @registry.register(bad_stream)
    @registry.register(good_stream)

    assert_nothing_raised { @registry.broadcast('{"test":true}') }
    assert_equal [ '{"test":true}' ], written
  end

  test "concurrent register and unregister does not corrupt state" do
    streams = 10.times.map do
      s = Object.new
      s.define_singleton_method(:write) { |_| }
      s
    end

    threads = streams.map { |s| Thread.new { @registry.register(s) } }
    threads.each(&:join)
    assert_equal 10, @registry.instance_variable_get(:@streams).size

    threads = streams.map { |s| Thread.new { @registry.unregister(s) } }
    threads.each(&:join)
    assert_equal 0, @registry.instance_variable_get(:@streams).size
  end
end
