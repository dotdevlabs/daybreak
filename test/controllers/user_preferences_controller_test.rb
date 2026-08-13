require "test_helper"

class UserPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    sign_in_as(@user)
  end

  test "PATCH user_preference with valid locale updates user locale" do
    patch user_preference_path, params: { locale: "fr" }
    assert_equal "fr", @user.reload.locale
  end

  test "PATCH user_preference redirects to root" do
    patch user_preference_path, params: { locale: "es" }
    assert_redirected_to root_path
  end

  test "PATCH user_preference with invalid locale does not change locale" do
    @user.update!(locale: "en")
    patch user_preference_path, params: { locale: "xx" }
    assert_equal "en", @user.reload.locale
  end

  test "PATCH user_preference accepts all supported locales" do
    User::SUPPORTED_LOCALES.each do |locale|
      patch user_preference_path, params: { locale: locale }
      assert_equal locale, @user.reload.locale
    end
  end

  test "PATCH user_preference requires authentication" do
    delete session_path
    patch user_preference_path, params: { locale: "fr" }
    assert_redirected_to root_path
  end
end
