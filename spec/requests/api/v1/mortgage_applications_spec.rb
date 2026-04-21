require 'rails_helper'

RSpec.describe "Api::V1::MortgageApplications", type: :request do
  let(:valid_params) do
    {
      mortgage_application: {
        annual_income:    60000,
        monthly_expenses: 500,
        deposit_amount:   60000,
        property_value:   300000,
        term_years:       25
      }
    }
  end

  describe "POST /api/v1/mortgage_applications" do
    context "with valid params" do
      it "returns 201 and the created application" do
        post "/api/v1/mortgage_applications", params: valid_params
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body).to include("annual_income", "property_value", "status")
      end
    end

    context "with invalid params" do
      it "returns 422 with error messages" do
        post "/api/v1/mortgage_applications", params: { mortgage_application: { annual_income: -1 } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key("errors")
      end
    end
  end

  describe "GET /api/v1/mortgage_applications/:id" do
    let!(:application) { create(:mortgage_application) }

    it "returns the application" do
      get "/api/v1/mortgage_applications/#{application.id}"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(application.id)
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/mortgage_applications/99999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
