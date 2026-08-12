require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    I18n.locale = :en
  end

  teardown do
    I18n.locale = I18n.default_locale
  end

  test "SUPPORTED_LOCALES contains all 7 required locales" do
    assert_equal %w[en es fr pt-BR pt-PT de it], User::SUPPORTED_LOCALES
  end

  test "locale allows nil" do
    user = users(:alice)
    user.locale = nil
    assert user.valid?
  end

  test "locale accepts supported locales" do
    user = users(:alice)
    User::SUPPORTED_LOCALES.each do |locale|
      user.locale = locale
      assert user.valid?, "Expected #{locale} to be valid"
    end
  end

  test "locale rejects unsupported locale strings" do
    user = users(:alice)
    user.locale = "xx"
    assert_not user.valid?
    assert_includes user.errors[:locale], "is not included in the list"
  end

  test "has_secure_password authenticates with correct password" do
    user = users(:alice)
    assert user.authenticate("password123")
  end

  test "has_secure_password rejects wrong password" do
    user = users(:alice)
    assert_not user.authenticate("wrongpassword")
  end

  test "email_address normalizes to lowercase and strips whitespace" do
    user = User.new(email_address: "  Alice@Example.COM  ", password: "secret123")
    user.valid?
    assert_equal "alice@example.com", user.email_address
  end

  test "email_address presence is required" do
    user = User.new(email_address: "", password: "secret123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique" do
    existing = users(:alice)
    user = User.new(email_address: existing.email_address, password: "secret123")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "email_address uniqueness is case-insensitive" do
    existing = users(:alice)
    user = User.new(email_address: existing.email_address.upcase, password: "secret123")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "email_address rejects invalid format" do
    user = User.new(email_address: "not-an-email", password: "secret123")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "email_address accepts valid format" do
    user = User.new(email_address: "valid@example.com", password: "secret123")
    assert user.valid?
  end

  test "generates_token_for password_reset produces a valid token" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    assert_not_nil token
    found = User.find_by_password_reset_token(token)
    assert_equal user.id, found.id
  end

  test "password_reset token is invalidated after password change" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    user.update!(password: "newpassword456")
    assert_nil User.find_by_password_reset_token(token)
  end

  test "has_many sessions dependent destroy" do
    user = users(:alice)
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")
    assert_equal 1, user.sessions.count
    user.destroy
    assert_equal 0, Session.where(user_id: user.id).count
  end
end
