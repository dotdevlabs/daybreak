class UserPreferencesController < ApplicationController
  def update
    User.current.update(locale: params[:locale])
    redirect_to root_path
  end
end
