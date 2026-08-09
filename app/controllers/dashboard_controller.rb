class DashboardController < ApplicationController
  def show
    @briefing = DailyBriefing.for_today
  end
end
