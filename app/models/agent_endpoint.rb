class AgentEndpoint < ApplicationRecord
  validates :callback_url, presence: true

  def self.current
    last
  end
end
