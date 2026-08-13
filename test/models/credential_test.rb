require "test_helper"

class CredentialTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "requires external_id" do
    cred = Credential.new(user: @user, public_key: "key", external_id: nil)
    assert_not cred.valid?
    assert_includes cred.errors[:external_id], "can't be blank"
  end

  test "requires public_key" do
    cred = Credential.new(user: @user, external_id: "ext-id", public_key: nil)
    assert_not cred.valid?
    assert_includes cred.errors[:public_key], "can't be blank"
  end

  test "external_id must be unique" do
    cred1 = @user.credentials.create!(external_id: "unique-id", public_key: "key1", sign_count: 0)
    cred2 = Credential.new(user: @user, public_key: "key2", external_id: cred1.external_id)
    assert_not cred2.valid?
  end

  test "belongs to user" do
    cred = @user.credentials.create!(external_id: "my-id", public_key: "key", sign_count: 0)
    assert_equal @user, cred.user
  end
end
