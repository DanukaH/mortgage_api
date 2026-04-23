require 'rails_helper'

RSpec.describe AffordabilityAssessor, type: :service do
  let(:application) { create(:mortgage_application) }


  subject(:result) { described_class.new(application).assess }

  describe '#assess' do
    it 'returns all required keys' do
      expect(result.keys).to contain_exactly(:loan_to_value, :debt_to_income,
                                             :maximum_borrowing, :decision, :explanation)
    end

    it 'calculates LTV correctly' do
      expect(result[:loan_to_value]).to eq(0.9)
    end

    it 'calculates DTI correctly' do
      expect(result[:debt_to_income]).to eq(0.4157)
    end

    it 'returns maximum borrowing as the lower of 4.5x income or 90% LTV' do
      expected = [ 60000 * 4.5, 300000 * 0.9 ].min.round(2)
      expect(result[:maximum_borrowing]).to eq(expected)
    end
  end

  context 'when application passes all affordability criteria' do
    it 'is approved' do
      expect(result[:decision]).to eq('approved')
    end

    it 'returns a passing explanation' do
      expect(result[:explanation]).to eq('Application meets all affordability criteria. LTV: 90.0%, DTI: 41.6%.')
    end
  end

  context 'when LTV is too high' do
    before { application.deposit_amount = 20000 } # This changes the LTV to 93.3%

    it 'declines the application' do
      expect(result[:decision]).to eq('declined')
    end

    it 'returns a declining explanation' do
      expected_pct = "#{(AffordabilityAssessor::MAX_LTV * 100).round(1)}%"
      expect(result[:explanation]).to include("Loan to Value Ratio (LTV) of 93.3% exceeds the maximum allowed #{expected_pct}.")
    end
  end

  context 'when DTI is too high' do
    before { application.annual_income = 15000 } # This changes the DTI to 166.3%

    it 'declines the application' do
      expect(result[:decision]).to eq('declined')
    end

    it 'returns a declining explanation' do
      expected_pct = "#{(AffordabilityAssessor::MAX_DTI * 100).round(1)}%"
      expect(result[:explanation]).to include("Debt to Income Ratio (DTI) of 166.3% exceeds the maximum allowed #{expected_pct}.")
    end
  end
end
