module Authenticatable
  extend ActiveSupport::Concern

  included do
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    before_action :authenticate!
  end

  private

  def expected_username
    ENV.fetch("API_USERNAME") { Rails.application.credentials.api_username.to_s }
  end

  def expected_password
    ENV.fetch("API_PASSWORD") { Rails.application.credentials.api_password.to_s }
  end

  def authenticate!
    authenticate_or_request_with_http_basic("Mortgage API") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &
        ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
    end
  end
end
