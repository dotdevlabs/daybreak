require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { I18n.locale = :en }
  teardown { I18n.locale = I18n.default_locale }

  test "SUPPORTED_LOCALES contains all 7 required locales" do
    assert_equal %w[en es fr pt-BR pt-PT de it], User::SUPPORTED_LOCALES
  end

  test "locale allows nil" do
    user = users(:alice)
    user.locale = nil
    assert user.valid?
  end

  test "locale accepts supported locales" do
    User::SUPPORTED_LOCALES.each do |locale|
      user = users(:alice)
      user.locale = locale
      assert user.valid?, "Expected #{locale} to be valid"
    end
  end

  test "locale rejects unsupported locale strings" do
    user = users(:alice)
    user.locale = "xx"
    assert_not user.valid?
  end

  test "email_address normalizes to lowercase and strips whitespace" do
    user = User.new(email_address: "  Alice@Example.COM  ")
    user.valid?
    assert_equal "alice@example.com", user.email_address
  end

  test "email_address presence is required" do
    user = User.new(email_address: "")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique" do
    existing = users(:alice)
    user = User.new(email_address: existing.email_address)
    assert_not user.valid?
  end

  test "email_address uniqueness is case-insensitive" do
    user = User.new(email_address: users(:alice).email_address.upcase)
    assert_not user.valid?
  end

  test "email_address rejects invalid format" do
    user = User.new(email_address: "not-an-email")
    assert_not user.valid?
  end

  test "webauthn_id is assigned on create" do
    user = User.create!(email_address: "new@example.com")
    assert user.webauthn_id.present?
  end

  test "webauthn_id is unique across users" do
    user1 = User.create!(email_address: "user1@example.com")
    user2 = User.create!(email_address: "user2@example.com")
    assert_not_equal user1.webauthn_id, user2.webauthn_id
  end

  test "verified? returns false when verified_at is nil" do
    user = users(:alice)
    user.verified_at = nil
    assert_not user.verified?
  end

  test "verified? returns true when verified_at is present" do
    user = users(:alice)
    assert user.verified?
  end

  test "verify! sets verified_at" do
    user = users(:alice)
    user.update!(verified_at: nil)
    user.verify!
    assert user.reload.verified?
  end

  test "generates_token_for email_verification produces valid token" do
    user = users(:alice)
    user.update!(verified_at: nil)
    token = user.generate_token_for(:email_verification)
    assert_not_nil token
    found = User.find_by_token_for(:email_verification, token)
    assert_equal user.id, found.id
  end

  test "email_verification token is invalidated after verification" do
    user = users(:alice)
    user.update!(verified_at: nil)
    token = user.generate_token_for(:email_verification)
    user.verify!
    assert_nil User.find_by_token_for(:email_verification, token)
  end

  test "has_many credentials dependent destroy" do
    user = users(:alice)
    user.credentials.create!(
      external_id: "test-ext-id",
      public_key:  "test-pub-key",
      sign_count:  0
    )
    assert_equal 1, user.credentials.count
    user.destroy
    assert_equal 0, Credential.where(user_id: user.id).count
  end

  test "has_many sessions dependent destroy" do
    user = users(:alice)
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")
    user.destroy
    assert_equal 0, Session.where(user_id: user.id).count
  end
end
