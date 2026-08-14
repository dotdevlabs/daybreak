class DashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    @briefing = authenticated? ? Current.user.account.daily_briefings.for_today : nil
  end
end
