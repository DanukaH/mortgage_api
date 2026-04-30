require 'rails_helper'

RSpec.describe AffordabilityAssessmentJob, type: :job do
  let(:application) { create(:mortgage_application) }

  describe '#perform' do
    it ' persists the assessment result on the application' do
      described_class.perform_now(application.id)
      application.reload

      expect(application.status).to eq('assessed')
      expect(application.decision).to be_in(%w[approved declined])
      expect(application.loan_to_value).to be_present
      expect(application.debt_to_income).to be_present
      expect(application.maximum_borrowing).to be_present
      expect(application.explanation).to be_present
      expect(application.assessed_at).to be_present
    end

    it 'does not reassess an already assessed application' do
      described_class.perform_now(application.id)
      original_assessed_at = application.reload.assessed_at

      travel 1.hour do
        described_class.perform_now(application.id)
        expect(application.reload.assessed_at).to be_within(1.second).of(original_assessed_at)
      end
    end
  end
end
