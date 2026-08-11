require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    User.destroy_all
  end

  test "current creates a user if none exists" do
    assert_equal 0, User.count
    user = User.current
    assert_not_nil user
    assert_equal 1, User.count
  end

  test "current returns the same record on repeated calls" do
    user1 = User.current
    user2 = User.current
    assert_equal user1.id, user2.id
    assert_equal 1, User.count
  end

  test "current creates user with nil locale" do
    user = User.current
    assert_nil user.locale
  end

  test "locale allows nil" do
    user = User.current
    user.locale = nil
    assert user.valid?
  end

  test "locale accepts supported locales" do
    user = User.current
    User::SUPPORTED_LOCALES.each do |locale|
      user.locale = locale
      assert user.valid?, "Expected #{locale} to be valid"
    end
  end

  test "locale rejects unsupported locale strings" do
    user = User.current
    user.locale = "xx"
    assert_not user.valid?
    assert_includes user.errors[:locale], "is not included in the list"
  end

  test "SUPPORTED_LOCALES contains all 7 required locales" do
    assert_equal %w[en es fr pt-BR pt-PT de it], User::SUPPORTED_LOCALES
  end
end
