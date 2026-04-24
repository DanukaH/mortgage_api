module AuthenticationHelper
  def auth_headers
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password123")
    { "Authorization" => credentials }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request

  config.before(:each, type: :request) do
    allow(Rails.application.credentials).to receive(:api_username).and_return("admin")
    allow(Rails.application.credentials).to receive(:api_password).and_return("password123")
  end
end
