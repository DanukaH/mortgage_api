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
  end
end
