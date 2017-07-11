module Auth
  def logged_in?
    !get_current_user.blank?
  end

  def login_required
    session[:return_to] = request.url

    redirect_to Rez::Application.config.ida.root_url unless logged_in?
  end


	# Verify local instance of user
	def find_or_init_local_user(master_id)
    if master_user = locate_master_user(master_id)

      local_user = User.find_or_create_by(uuid: master_id)
      local_user.identity = master_user.to_json

      local_user.login = local_user.identity['username']

      local_user.save

      #  e = local_user.errors.full_messages
    end

    local_user

  end


  protected

    def get_current_user

      if session[:ida_id].blank?
        @current_user = nil

      elsif @current_user.blank?
        # verify that the global user identifier exists in session
        if master_id = session[:ida_id]
          # locate the user locally or initialize a new instance if it cannot be found
          #  .. will return nil if user cannot be located
          @current_user = find_or_init_local_user(master_id)
        end
      end

      @current_user

    end

    def init_auth_service
      connect = Faraday.new(Rez::Application.config.ida.root_url, ssl: {verify: false}) do |c|
        c.use Faraday::Request::UrlEncoded  # encode request params as "www-form-urlencoded"
        c.use Faraday::Response::Logger     # log request & response to STDOUT
        c.use Faraday::Adapter::NetHttp     # perform requests with Net::HTTP
        c.use FaradayMiddleware::ParseJson, content_type: 'application/json'
        c.use Faraday::Request::TokenAuthentication, handshake
      end
      connect
    end

    def locate_master_user(id)
      begin
        #~ Establish a connection to the media processor and pass the original upload along
        connect = init_auth_service

        response = connect.get do |req|
          req.url "/api/v1/users/#{id}"
          req.headers["Authorization"] = "Token token=\"#{handshake}\""
        end

        if response.success?
          response.body
        end

      rescue Faraday::Error::ConnectionFailed => e
        logger.error "Ida lookup failed -> #{e}"
      end
    end

    def handshake
      'c6a7435a-4e3b-4393-9355-509cf93601a1'
    end


end
