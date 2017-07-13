class SessionsController < ApplicationController
  skip_before_action :login_required, :logged_in?, :cart, :app_setup_check,
                     :load_configs, :seen_app_configs, :fix_cart_date, :set_view_mode,
                     :check_view_mode, :make_cart_compatible
  def new
    if logged_in?
      redirect_to Rez::Application.config.stew.root_url
    else
      @current_user = nil
      redirect_to Rez::Application.config.ida.root_url
    end

  end
  def destroy
    session[:cart] = nil
    redirect_to "#{Rez::Application.config.ida.root_url}/sign_out"
  end
end
