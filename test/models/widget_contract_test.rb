require "test_helper"

class WidgetContractTest < ActiveSupport::TestCase
  CONTRACT_PATH = Rails.root.join("public/widget_contract.json")
  CONTRACT = JSON.parse(CONTRACT_PATH.read)

  test "contract file is valid JSON" do
    assert CONTRACT.is_a?(Hash)
  end

  test "contract type enum matches WidgetMessage::WIDGET_TYPES" do
    contract_types = CONTRACT.dig("properties", "type", "enum")
    assert_equal WidgetMessage::WIDGET_TYPES.sort, contract_types.sort
  end

  test "contract defines a schema entry for each widget type" do
    WidgetMessage::WIDGET_TYPES.each do |widget_type|
      assert CONTRACT.dig("$defs", widget_type),
             "Contract missing $defs entry for #{widget_type}"
    end
  end

  test "each contract example is accepted by WidgetMessage" do
    WidgetMessage::WIDGET_TYPES.each do |widget_type|
      examples = CONTRACT.dig("$defs", widget_type, "examples") || []
      assert examples.any?, "Contract has no examples for #{widget_type}"
      examples.each_with_index do |example, i|
        msg = WidgetMessage.new(type: widget_type, data: example)
        assert msg.valid?,
               "Contract example #{i} for #{widget_type} rejected: #{msg.errors.full_messages}"
      end
    end
  end

  test "contract defines outbound key with delivery endpoints" do
    outbound = CONTRACT["outbound"]
    assert outbound, "Contract missing top-level 'outbound' key"
    assert_equal "GET /api/events", outbound["events_endpoint"]
    assert_equal "POST /api/agent/registrations", outbound["registration_endpoint"]
    assert outbound["message_format"], "outbound missing message_format"
  end

  test "contract $defs includes outbound_action with required fields" do
    schema = CONTRACT.dig("$defs", "outbound_action")
    assert schema, "Contract missing $defs/outbound_action"
    assert_equal %w[type action data].sort, schema["required"].sort
    assert_equal [ "action_items" ], schema.dig("properties", "type", "enum")
    assert_equal [ "item_completed" ], schema.dig("properties", "action", "enum")
  end

  test "outbound_action examples have correct structure" do
    examples = CONTRACT.dig("$defs", "outbound_action", "examples") || []
    assert examples.any?, "outbound_action has no examples"
    examples.each_with_index do |example, i|
      assert_equal "action_items", example["type"], "Example #{i}: wrong type"
      assert_equal "item_completed", example["action"], "Example #{i}: wrong action"
      assert example.dig("data", "context"), "Example #{i}: missing data.context"
      assert example.dig("data", "item", "text"), "Example #{i}: missing data.item.text"
    end
  end
end
