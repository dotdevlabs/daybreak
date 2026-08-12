class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  private

  def set_locale
    user_locale = current_user&.locale.presence
    browser_locale = parse_accept_language
    I18n.locale = (user_locale || browser_locale || I18n.default_locale).to_sym
  end

  def parse_accept_language
    header = request.env["HTTP_ACCEPT_LANGUAGE"]
    return nil unless header

    available = I18n.available_locales.map(&:to_s)
    header.scan(/[a-zA-Z]{2,3}(?:-[a-zA-Z]{2,3})?/).each do |tag|
      return tag if available.include?(tag)
      prefix_match = available.find { |l| l.start_with?("#{tag}-") }
      return prefix_match if prefix_match
    end
    nil
  end
end
