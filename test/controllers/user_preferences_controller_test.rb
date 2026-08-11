require "test_helper"

class UserPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.destroy_all
    User.current
  end

  teardown do
    User.destroy_all
  end

  test "PATCH user_preference with valid locale updates user locale" do
    patch user_preference_path, params: { locale: "fr" }
    assert_equal "fr", User.current.locale
  end

  test "PATCH user_preference redirects to root" do
    patch user_preference_path, params: { locale: "es" }
    assert_redirected_to root_path
  end

  test "PATCH user_preference with invalid locale does not change locale" do
    User.current.update!(locale: "en")
    patch user_preference_path, params: { locale: "xx" }
    assert_equal "en", User.current.locale
  end

  test "PATCH user_preference accepts all supported locales" do
    User::SUPPORTED_LOCALES.each do |locale|
      patch user_preference_path, params: { locale: locale }
      assert_equal locale, User.current.locale
    end
  end
end
