require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "POST registration with valid params creates user, session, and redirects to root" do
    assert_difference "User.count", 1 do
      assert_difference "Session.count", 1 do
        post registration_path, params: {
          email_address: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      end
    end
    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "POST registration with invalid email returns 422 and renders overlay in register mode" do
    post registration_path, params: {
      email_address: "not-an-email",
      password: "password123",
      password_confirmation: "password123"
    }
    assert_response :unprocessable_entity
    assert_select ".auth-overlay"
  end

  test "POST registration with mismatched passwords returns 422 with errors" do
    post registration_path, params: {
      email_address: "newuser@example.com",
      password: "password123",
      password_confirmation: "different"
    }
    assert_response :unprocessable_entity
    assert_select ".auth-overlay__errors"
  end

  test "POST registration with duplicate email returns 422 with uniqueness error" do
    existing = users(:alice)
    post registration_path, params: {
      email_address: existing.email_address,
      password: "password123",
      password_confirmation: "password123"
    }
    assert_response :unprocessable_entity
    assert_select ".auth-overlay__errors"
  end

  test "POST registration with blank email returns 422" do
    post registration_path, params: {
      email_address: "",
      password: "password123",
      password_confirmation: "password123"
    }
    assert_response :unprocessable_entity
  end
end
