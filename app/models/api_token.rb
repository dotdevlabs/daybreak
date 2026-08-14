class ApiToken < ApplicationRecord
  belongs_to :account

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
