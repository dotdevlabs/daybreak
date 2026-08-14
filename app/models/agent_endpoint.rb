class AgentEndpoint < ApplicationRecord
  belongs_to :account

  validates :callback_url, presence: true
end
