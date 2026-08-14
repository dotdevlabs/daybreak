class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :daily_briefings, dependent: :destroy
  has_many :agent_endpoints, dependent: :destroy
end
