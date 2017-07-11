class SessionsController < ApplicationController
  def new
    if logged_in?
      redirect_to Rez::Application.config.stew.root_url
    else
      @current_user = nil
      redirect_to Rez::Application.config.ida.root_url
    end

  end
  def destroy
    redirect_to "#{Rez::Application.config.ida.root_url}/sign_out"
  end
end
