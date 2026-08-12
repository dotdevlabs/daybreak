class DashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    @briefing = DailyBriefing.for_today
  end
end
