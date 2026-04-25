require 'rails_helper'

RSpec.describe MortgageApplication, type: :model do
  subject(:application) { build(:mortgage_application) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:annual_income) }
    it { is_expected.to validate_presence_of(:monthly_expenses) }
    it { is_expected.to validate_presence_of(:deposit_amount) }
    it { is_expected.to validate_presence_of(:property_value) }
    it { is_expected.to validate_presence_of(:term_years) }

    it { is_expected.to validate_numericality_of(:annual_income).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:monthly_expenses).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:deposit_amount).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:property_value).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:term_years).only_integer.is_greater_than(0).is_less_than_or_equal_to(40) }

    it { is_expected.to validate_inclusion_of(:status).in_array(MortgageApplication::STATUS) }
    it { is_expected.to validate_inclusion_of(:decision).in_array(MortgageApplication::DECISION).allow_nil }

    describe 'deposit vs property value' do
      it 'is invalid when deposit equals property value' do
        application.deposit_amount = application.property_value
        expect(application).not_to be_valid
        expect(application.errors[:deposit_amount]).to include("must be less than the property value")
      end

      it 'is invalid when deposit exceeds property value' do
        application.deposit_amount = application.property_value + 1
        expect(application).not_to be_valid
        expect(application.errors[:deposit_amount]).to include("must be less than the property value")
      end

      it 'is valid when deposit is less than property value' do
        application.deposit_amount = application.property_value - 1
        expect(application).to be_valid
      end
    end
  end

  describe '#loan_amount' do
    it 'returns property value minus deposit' do
      application.property_value = 300000
      application.deposit_amount = 60000
      expect(application.loan_amount).to eq(240000)
    end
  end

  describe '#assessed?' do
    it 'is false for a new application' do
      expect(application.assessed?).to be false
    end

    it 'is true once status becomes assessed' do
      application.status = 'assessed'
      expect(application.assessed?).to be true
    end
  end

  describe 'default status' do
    it 'defaults to pending before validation' do
      expect(application).to be_valid
      expect(application.status).to eq('pending')
    end
  end
end
