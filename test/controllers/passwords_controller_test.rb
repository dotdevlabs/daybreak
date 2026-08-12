require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET passwords/new renders successfully" do
    get new_password_path
    assert_response :success
  end

  test "POST passwords with registered email redirects to root with notice" do
    user = users(:alice)
    assert_emails 1 do
      post passwords_path, params: { email_address: user.email_address }
    end
    assert_redirected_to root_path
    assert_not_nil flash[:notice]
  end

  test "POST passwords with unknown email still redirects to root with notice (no info leakage)" do
    assert_emails 0 do
      post passwords_path, params: { email_address: "nobody@example.com" }
    end
    assert_redirected_to root_path
    assert_not_nil flash[:notice]
  end

  test "GET passwords/:token/edit with valid token renders edit form" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    get edit_password_path(token)
    assert_response :success
  end

  test "GET passwords/:token/edit with invalid token redirects to new with alert" do
    get edit_password_path("invalidtoken")
    assert_redirected_to new_password_path
    assert_not_nil flash[:alert]
  end

  test "PATCH passwords/:token with valid params updates password and redirects to root" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    patch password_path(token), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    assert_redirected_to root_path
    assert user.reload.authenticate("newpassword456")
  end

  test "PATCH passwords/:token with mismatched confirmation re-renders edit" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    patch password_path(token), params: { password: "newpassword456", password_confirmation: "different" }
    assert_response :unprocessable_entity
  end

  test "PATCH passwords/:token with invalid token redirects to new with alert" do
    patch password_path("badtoken"), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    assert_redirected_to new_password_path
    assert_not_nil flash[:alert]
  end

  test "password reset token is invalidated after password change" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    patch password_path(token), params: { password: "newpassword456", password_confirmation: "newpassword456" }
    get edit_password_path(token)
    assert_redirected_to new_password_path
  end
end
