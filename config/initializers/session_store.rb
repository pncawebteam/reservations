Rez::Application.config.session_store :active_record_store, domain: "#{Rez::Application.config.rez.domain}", key: '_pnca_ida_session'

ActiveRecord::SessionStore::Session.establish_connection "ida_#{Rails.env}".to_sym
