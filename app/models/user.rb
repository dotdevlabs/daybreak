class User < ApplicationRecord
  SUPPORTED_LOCALES = %w[en es fr pt-BR pt-PT de it].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt.last(10)
  end
end
