require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to user" do
    session = Session.new(ip_address: "127.0.0.1", user_agent: "Test")
    assert_not session.valid?
    assert session.errors[:user].any?
  end

  test "is valid with a user" do
    session = Session.new(user: users(:alice), ip_address: "127.0.0.1", user_agent: "Test")
    assert session.valid?
  end

  test "is destroyed when user is destroyed" do
    user = users(:alice)
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")
    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
