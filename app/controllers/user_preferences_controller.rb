class UserPreferencesController < ApplicationController
  def update
    current_user.update(locale: params[:locale])
    redirect_to root_path
  end
end
