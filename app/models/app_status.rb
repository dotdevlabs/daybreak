class AppStatus
  def self.as_jsonapi
    {
      type: "status",
      id: "current",
      attributes: {
        version:    ENV["APP_VERSION"],
        sha:        ENV["APP_SHA"],
        db_version: current_db_version
      },
      links: { self: "/api/status" }
    }
  end

  def self.current_db_version
    ApplicationRecord.connection.select_value(
      "SELECT MAX(version) FROM schema_migrations"
    )
  rescue StandardError
    nil
  end
end
