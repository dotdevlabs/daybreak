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
end
