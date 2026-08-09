require "test_helper"

class OutboundMessageTest < ActiveSupport::TestCase
  def setup
    @message = OutboundMessage.new(
      type: "action_items",
      action: "item_completed",
      data: { "context" => "personal", "item" => { "text" => "Call dentist", "priority" => "high" } }
    )
    AgentPushRegistry.instance.instance_variable_set(:@streams, [])  # reset between tests
  end

  test "as_json returns correct type, action, and data keys" do
    json = @message.as_json
    assert_equal "action_items", json["type"]
    assert_equal "item_completed", json["action"]
    assert_equal "personal", json.dig("data", "context")
    assert_equal "Call dentist", json.dig("data", "item", "text")
    assert_equal "high", json.dig("data", "item", "priority")
  end

  test "deliver returns true when push broadcast succeeds" do
    stream = Object.new
    stream.define_singleton_method(:write) { |_| }
    AgentPushRegistry.instance.register(stream)

    assert @message.deliver
  end

  test "deliver returns true even when no push connection and no endpoint" do
    AgentEndpoint.delete_all
    assert @message.deliver
  end

  test "deliver falls back to callback endpoint when no push connection" do
    # Use a local TCP server to capture the HTTP POST
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    received_body = nil

    server_thread = Thread.new do
      socket = server.accept
      raw = ""
      while (line = socket.gets) && line != "\r\n"
        raw += line
      end
      content_length = raw.match(/Content-Length: (\d+)/i)&.[](1).to_i
      received_body = socket.read(content_length)
      socket.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok")
      socket.close
    end

    AgentEndpoint.create!(callback_url: "http://127.0.0.1:#{port}/callback")
    assert @message.deliver
    server_thread.join(5)
    server.close

    parsed = JSON.parse(received_body)
    assert_equal "action_items", parsed["type"]
    assert_equal "item_completed", parsed["action"]
  end

  test "deliver returns true and does not raise when callback HTTP fails" do
    # Port 1 is privileged and will refuse the connection
    AgentEndpoint.create!(callback_url: "http://127.0.0.1:1/callback")
    assert_nothing_raised { assert @message.deliver }
  end
end
