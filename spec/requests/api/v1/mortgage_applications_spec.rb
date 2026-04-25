require 'rails_helper'

RSpec.describe 'Api::V1::MortgageApplications', type: :request do
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

  describe 'GET /api/v1/mortgage_applications' do
    let!(:applications) { create_list(:mortgage_application, 3) }

    it 'returns all applications' do
      get '/api/v1/mortgage_applications', headers: auth_headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(3)
    end

    it 'returns an empty array when there are no applications' do
      MortgageApplication.delete_all
      get '/api/v1/mortgage_applications', headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe 'POST /api/v1/mortgage_applications' do
    context 'with valid params' do
      it 'returns 201 and the created application' do
        post '/api/v1/mortgage_applications',
             params: valid_params,
             headers: auth_headers
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body).to include('annual_income', 'property_value')
      end
    end

    context 'with invalid params' do
      it 'returns 422 with error messages' do
        post '/api/v1/mortgage_applications',
             params: { mortgage_application: { annual_income: -1 } },
             headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end
  end

  describe 'GET /api/v1/mortgage_applications/:id' do
    let!(:application) { create(:mortgage_application) }

    it 'returns the application' do
      get "/api/v1/mortgage_applications/#{application.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(application.id)
    end

    it 'returns 404 for an unknown id' do
      get '/api/v1/mortgage_applications/99999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/mortgage_applications/:id/assessment' do
    let!(:application) { create(:mortgage_application) }

    context 'when the application is pending' do
      it 'enqueues a background job and returns 202' do
        expect {
          get "/api/v1/mortgage_applications/#{application.id}/assessment", headers: auth_headers
        }.to have_enqueued_job(AffordabilityAssessmentJob).with(application.id)

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)['status']).to eq('assessing')
      end

      it 'moves the application status to assessing' do
        get "/api/v1/mortgage_applications/#{application.id}/assessment", headers: auth_headers
        expect(application.reload.status).to eq('assessing')
      end
    end

    context 'when the application is already being assessed' do
      before { application.update!(status: 'assessing') }

      it 'returns 202 without enqueuing another job' do
        expect {
          get "/api/v1/mortgage_applications/#{application.id}/assessment", headers: auth_headers
        }.not_to have_enqueued_job(AffordabilityAssessmentJob)

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when the application has been assessed' do
      before do
        perform_enqueued_jobs do
          AffordabilityAssessmentJob.perform_later(application.id)
        end
      end

      it 'has status assessed' do
        expect(application.reload.status).to eq('assessed')
      end

      it 'has a decision of approved or declined' do
        expect(application.reload.decision).to be_in(%w[approved declined])
      end

      it 'returns the cached result with 200' do
        get "/api/v1/mortgage_applications/#{application.id}/assessment", headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.keys).to contain_exactly('loan_to_value', 'debt_to_income', 'maximum_borrowing',
                                             'decision', 'explanation', 'assessed_at')
      end
    end

    it 'returns 404 for an unknown id' do
      get '/api/v1/mortgage_applications/99999/assessment', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
