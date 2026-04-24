require 'rails_helper'

RSpec.describe 'API Authentication', type: :request do
  let!(:application) { create(:mortgage_application) }

  describe 'GET /api/v1/mortgage_applications/:id' do
    it 'returns 401 when credentials are provided' do
      get "/api/v1/mortgage_applications/#{application.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when credentials are incorrect' do
      headers = { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('invalid', 'invalid') }
      get "/api/v1/mortgage_applications/#{application.id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it ' returns 200 when credentials are correct' do
      get "/api/v1/mortgage_applications/#{application.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end
end
