class WidgetCatalog
  CONTRACT_PATH = Rails.root.join("public/widget_contract.json")

  def self.all
    contract = JSON.parse(File.read(CONTRACT_PATH))
    WidgetMessage::WIDGET_TYPES.map do |widget_type|
      defn = contract.dig("$defs", widget_type) || {}
      new(
        id: widget_type,
        name: defn["title"] || widget_type,
        description: defn["description"] || "",
        schema: defn.except("title", "description", "examples")
      )
    end
  end

  attr_reader :id, :name, :description, :schema

  def initialize(id:, name:, description:, schema:)
    @id = id
    @name = name
    @description = description
    @schema = schema
  end

  def as_jsonapi
    {
      type: "widget_types",
      id: id,
      attributes: { name: name, description: description, schema: schema }
    }
  end
end
