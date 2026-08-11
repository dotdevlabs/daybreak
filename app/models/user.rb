class User < ApplicationRecord
  SUPPORTED_LOCALES = %w[en es fr pt-BR pt-PT de it].freeze

  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true

  def self.current
    first_or_create!
  end
end
