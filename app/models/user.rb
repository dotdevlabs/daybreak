class User < ApplicationRecord
  SUPPORTED_LOCALES = %w[en es fr pt-BR pt-PT de it].freeze

  has_many :sessions,    dependent: :destroy
  has_many :credentials, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  generates_token_for :email_verification, expires_in: 24.hours do
    verified_at.to_i
  end

  before_create :assign_webauthn_id

  def verified?
    verified_at.present?
  end

  def verify!
    update!(verified_at: Time.current)
  end

  private

  def assign_webauthn_id
    self.webauthn_id ||= WebAuthn.generate_user_id
  end
end
